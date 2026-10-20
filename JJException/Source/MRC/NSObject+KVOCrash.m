//
//  NSObject+KVOCrash.m
//  JJException
//
//  Created by Jezz on 2018/8/29.
//  Copyright © 2018年 Jezz. All rights reserved.
//
//  Rewritten for the nattychao fork. What changed and why:
//
//  1. Two containers per object. Upstream attached "I am the subject" and
//     "I am the observer" bookkeeping under the SAME associated-object key, so the
//     second role overwrote the first and its registrations were lost. Now a single
//     container stores items tagged with a role, so nothing is lost.
//
//  2. Weak references. Upstream kept observer/whichObject as raw `assign` pointers
//     in MRC code; once an object died the bookkeeping held dangling pointers and
//     `if (item.observer)` could not detect it. Observer/subject are now held by
//     JJWeakObjectBox (ARC-compiled) and zero out on dealloc.
//
//  3. No Foundation calls while the lock is held. Upstream held a semaphore across
//     removeObserver:forKeyPath:, so any callback re-entering KVO deadlocked.
//
//  4. No removal during the subject's own dealloc on iOS 18+. Foundation changed
//     NSKVONotifying_X's dealloc to run the original dealloc inside
//     __NSKVOPerformWithDeallocatingObservable; calling removeObserver from there
//     double-frees NSKeyValueObservationInfo (upstream issue #147). It is also
//     unnecessary: since iOS 18 NSKeyValueObservance holds the observer weakly.
//
//  5. Duplicate registrations are recorded per call (including context/options),
//     and removes consume exactly one record, so bookkeeping stays balanced.
//     Upstream de-duplicated on (observer, keyPath) only and dropped context.
//
//  6. Every Foundation call from a hook is wrapped: add/remove/observeValue all
//     report through JJExceptionGuardKVOCrash instead of killing the app.
//

#import "NSObject+KVOCrash.h"
#import "NSObject+SwizzleHook.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "JJExceptionProxy.h"
#import "JJWeakObjectBox.h"

static const char DeallocKVOKey;

#pragma mark - Record

@interface JJKVOItem : NSObject

/// Weak: the observer may die first.
@property (nonatomic, retain) JJWeakObjectBox *observerBox;
/// Weak: the subject may die first.
@property (nonatomic, retain) JJWeakObjectBox *subjectBox;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, assign) NSKeyValueObservingOptions options;
@property (nonatomic, assign) void *context;
/// YES when `self` (the owner of the container) is the observer, NO when it is the subject.
@property (nonatomic, assign) BOOL observerRole;

@end

@implementation JJKVOItem

- (void)dealloc {
    [_observerBox release];
    [_subjectBox release];
    [_keyPath release];
    [super dealloc];
}

- (BOOL)matchesObserver:(id)observer subject:(id)subject keyPath:(NSString *)keyPath context:(void *)context {
    if (![self.keyPath isEqualToString:keyPath ?: @""]) {
        return NO;
    }
    if (self.observerBox.object != observer) {
        return NO;
    }
    if (self.subjectBox.object != subject) {
        return NO;
    }
    if (context) {
        return self.context == context;
    }
    return YES;
}

@end

#pragma mark - Container

/// One global lock: containers are tiny and contention is irrelevant, whereas
/// per-container locks would risk lock-ordering issues when both the observer's
/// and the subject's containers are touched by the same call.
static NSRecursiveLock *jj_kvoLock(void) {
    static NSRecursiveLock *lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [[NSRecursiveLock alloc] init];
        lock.name = @"com.github.nattychao.JJException.kvo";
    });
    return lock;
}

@interface JJKVOContainer : NSObject
@property (nonatomic, retain) NSMutableArray<JJKVOItem *> *items;
@end

@implementation JJKVOContainer

- (instancetype)init {
    self = [super init];
    if (self) {
        _items = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_items release];
    [super dealloc];
}

@end

static JJKVOContainer *jj_kvoContainer(id object, BOOL create) {
    if (!object) {
        return nil;
    }
    NSRecursiveLock *lock = jj_kvoLock();
    [lock lock];
    JJKVOContainer *container = objc_getAssociatedObject(object, &DeallocKVOKey);
    if (!container && create) {
        container = [[JJKVOContainer alloc] init];
        objc_setAssociatedObject(object, &DeallocKVOKey, container, OBJC_ASSOCIATION_RETAIN);
        [container release];
    }
    [lock unlock];
    return container;
}

static void jj_kvoRecord(id owner, id observer, id subject, NSString *keyPath,
                         NSKeyValueObservingOptions options, void *context, BOOL observerRole) {
    if (!owner || !observer || !subject || !keyPath) {
        return;
    }
    JJKVOContainer *container = jj_kvoContainer(owner, YES);
    if (!container) {
        return;
    }

    JJKVOItem *item = [[JJKVOItem alloc] init];
    item.observerBox = [[[JJWeakObjectBox alloc] initWithObject:observer] autorelease];
    item.subjectBox = [[[JJWeakObjectBox alloc] initWithObject:subject] autorelease];
    item.keyPath = keyPath;
    item.options = options;
    item.context = context;
    item.observerRole = observerRole;

    NSRecursiveLock *lock = jj_kvoLock();
    [lock lock];
    [container.items addObject:item];
    [lock unlock];

    [item release];
}

/// Removes at most one matching record. Returns YES when something was consumed.
static BOOL jj_kvoConsumeRecord(id owner, id observer, id subject, NSString *keyPath, void *context) {
    if (!owner) {
        return NO;
    }
    JJKVOContainer *container = jj_kvoContainer(owner, NO);
    if (!container) {
        return NO;
    }

    NSRecursiveLock *lock = jj_kvoLock();
    [lock lock];
    NSUInteger index = NSNotFound;
    for (NSUInteger i = 0; i < container.items.count; i++) {
        if ([container.items[i] matchesObserver:observer subject:subject keyPath:keyPath context:context]) {
            index = i;
            break;
        }
    }
    if (index != NSNotFound) {
        [container.items removeObjectAtIndex:index];
    }
    [lock unlock];
    return index != NSNotFound;
}

static NSArray<JJKVOItem *> *jj_kvoSnapshot(id owner, BOOL observerRole) {
    if (!owner) {
        return @[];
    }
    JJKVOContainer *container = jj_kvoContainer(owner, NO);
    if (!container) {
        return @[];
    }

    NSRecursiveLock *lock = jj_kvoLock();
    [lock lock];
    NSMutableArray *result = [NSMutableArray array];
    for (JJKVOItem *item in container.items) {
        if (item.observerRole == observerRole) {
            [result addObject:item];
        }
    }
    [lock unlock];
    return result;
}

static void jj_kvoClear(id owner) {
    JJKVOContainer *container = jj_kvoContainer(owner, NO);
    if (!container) {
        return;
    }
    NSRecursiveLock *lock = jj_kvoLock();
    [lock lock];
    [container.items removeAllObjects];
    [lock unlock];
}

/// YES when the guard is allowed to remove observers from a subject that is
/// currently deallocating. See the file header, point 4.
static BOOL jj_kvoAllowsSubjectCleanupDuringDealloc(void) {
    if (@available(iOS 18.0, *)) {
        return NO;
    }
    return YES;
}

#pragma mark - Hook

@implementation NSObject (KVOCrash)

+ (void)jj_swizzleKVOCrash{
    swizzleInstanceMethod([self class], @selector(addObserver:forKeyPath:options:context:), @selector(hookAddObserver:forKeyPath:options:context:));
    swizzleInstanceMethod([self class], @selector(removeObserver:forKeyPath:), @selector(hookRemoveObserver:forKeyPath:));
    swizzleInstanceMethod([self class], @selector(removeObserver:forKeyPath:context:), @selector(hookRemoveObserver:forKeyPath:context:));
    swizzleInstanceMethod([self class], @selector(observeValueForKeyPath:ofObject:change:context:), @selector(hookObserveValueForKeyPath:ofObject:change:context:));
}

- (void)hookAddObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context{
    if (!JJExceptionGuardEnabled(JJExceptionGuardKVOCrash)) {
        [self hookAddObserver:observer forKeyPath:keyPath options:options context:context];
        return;
    }
    if ([self ignoreKVOInstanceClass:observer]) {
        [self hookAddObserver:observer forKeyPath:keyPath options:options context:context];
        return;
    }

    if (!observer) {
        handleCrashException(JJExceptionGuardKVOCrash, @"KVO addObserver nil observer");
        return;
    }
    if (keyPath.length == 0) {
        handleCrashException(JJExceptionGuardKVOCrash, @"KVO addObserver nil or empty keyPath");
        return;
    }

    @try {
        [self hookAddObserver:observer forKeyPath:keyPath options:options context:context];
    } @catch (NSException *exception) {
        handleCrashException(JJExceptionGuardKVOCrash, [NSString stringWithFormat:@"KVO addObserver failed: %@", exception.reason]);
        return;
    }

    // Recorded after the real registration succeeded, so the bookkeeping never
    // claims a relation Foundation does not know about.
    jj_kvoRecord(self, observer, self, keyPath, options, context, NO);
    jj_kvoRecord(observer, observer, self, keyPath, options, context, YES);

    // Dealloc hooks exist only to clean up registrations at teardown. iOS 18+
    // performs that teardown itself (and crashes if we interfere), so there is
    // nothing to swizzle there.
    if (jj_kvoAllowsSubjectCleanupDuringDealloc()) {
        jj_swizzleDeallocIfNeeded(self.class);
        jj_swizzleDeallocIfNeeded(observer.class);
    }
}

- (void)hookRemoveObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void*)context{
    if (!JJExceptionGuardEnabled(JJExceptionGuardKVOCrash)) {
        [self hookRemoveObserver:observer forKeyPath:keyPath context:context];
        return;
    }
    if ([self ignoreKVOInstanceClass:observer]) {
        [self hookRemoveObserver:observer forKeyPath:keyPath context:context];
        return;
    }

    if (!observer || !keyPath) {
        handleCrashException(JJExceptionGuardKVOCrash, @"KVO removeObserver nil observer or keyPath");
        return;
    }

    @try {
        [self hookRemoveObserver:observer forKeyPath:keyPath context:context];
    } @catch (NSException *exception) {
        // "Cannot remove an observer ... because it is not registered" used to be
        // a guaranteed crash. Reporting it keeps the app alive.
        handleCrashException(JJExceptionGuardKVOCrash, [NSString stringWithFormat:@"KVO removeObserver failed: %@", exception.reason]);
    }

    jj_kvoConsumeRecord(self, observer, self, keyPath, context);
    jj_kvoConsumeRecord(observer, observer, self, keyPath, context);
}

- (void)hookRemoveObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath{
    if (!JJExceptionGuardEnabled(JJExceptionGuardKVOCrash)) {
        [self hookRemoveObserver:observer forKeyPath:keyPath];
        return;
    }
    if ([self ignoreKVOInstanceClass:observer]) {
        [self hookRemoveObserver:observer forKeyPath:keyPath];
        return;
    }

    if (!observer || !keyPath) {
        handleCrashException(JJExceptionGuardKVOCrash, @"KVO removeObserver nil observer or keyPath");
        return;
    }

    @try {
        [self hookRemoveObserver:observer forKeyPath:keyPath];
    } @catch (NSException *exception) {
        handleCrashException(JJExceptionGuardKVOCrash, [NSString stringWithFormat:@"KVO removeObserver failed: %@", exception.reason]);
    }

    jj_kvoConsumeRecord(self, observer, self, keyPath, NULL);
    jj_kvoConsumeRecord(observer, observer, self, keyPath, NULL);
}

- (void)hookObserveValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (!JJExceptionGuardEnabled(JJExceptionGuardKVOCrash)) {
        [self hookObserveValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if ([self ignoreKVOInstanceClass:object]) {
        [self hookObserveValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    @try {
        [self hookObserveValueForKeyPath:keyPath ofObject:object change:change context:context];
    } @catch (NSException *exception) {
        handleCrashException(JJExceptionGuardKVOCrash, [NSString stringWithFormat:@"KVO callback threw: %@", exception.reason]);
    }
}

/**
 Ignore Special Library

 @param object Instance Class
 @return YES or NO
 */
- (BOOL)ignoreKVOInstanceClass:(id)object{

    if (!object) {
        return NO;
    }

    //Ignore ReactiveCocoa
    if (object_getClass(object) == objc_getClass("RACKVOProxy")) {
        return YES;
    }

    //Ignore AMAP
    NSString* className = NSStringFromClass(object_getClass(object));
    if ([className hasPrefix:@"AMap"]) {
        return YES;
    }

    return NO;
}

/**
 * Called from the swizzled -dealloc (installed only on systems that need it).
 * Never touches Foundation while holding the bookkeeping lock.
 */
- (void)jj_cleanKVO{
    // Fast path: most objects never took part in KVO, and dealloc is a bad place
    // to do work. One associated-object lookup instead of three lock round-trips.
    if (!jj_kvoContainer(self, NO)) {
        return;
    }

    BOOL allowsSubjectCleanup = jj_kvoAllowsSubjectCleanupDuringDealloc();

    // Case 1: this object is an observer. Removing itself from live subjects is
    // safe on every OS - the subject is not the object being torn down.
    NSArray<JJKVOItem *> *observedItems = jj_kvoSnapshot(self, YES);
    for (JJKVOItem *item in observedItems) {
        id subject = item.subjectBox.object;
        if (!subject) {
            continue;
        }
        @try {
            if (@available(iOS 11.0, *)) {
                [subject removeObserver:self forKeyPath:item.keyPath context:item.context];
            } else {
                [subject removeObserver:self forKeyPath:item.keyPath];
            }
        } @catch (NSException *exception) {
            // Swallow: dealloc must never throw.
        }
    }

    // Case 2: this object is the subject. On iOS 18+ Foundation tears the
    // observation info down itself; doing it here double-frees it (#147).
    if (allowsSubjectCleanup) {
        NSArray<JJKVOItem *> *observerItems = jj_kvoSnapshot(self, NO);
        for (JJKVOItem *item in observerItems) {
            id observer = item.observerBox.object;
            if (!observer) {
                continue;
            }
            @try {
                if (@available(iOS 11.0, *)) {
                    [self removeObserver:observer forKeyPath:item.keyPath context:item.context];
                } else {
                    [self removeObserver:observer forKeyPath:item.keyPath];
                }
            } @catch (NSException *exception) {
                // Swallow: dealloc must never throw.
            }
        }
    }

    jj_kvoClear(self);
}

@end
