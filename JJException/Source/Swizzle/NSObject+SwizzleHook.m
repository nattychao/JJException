//
//  NSObject+SwizzleHook.m
//  JJException
//
//  Created by Jezz on 2018/7/10.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import "NSObject+SwizzleHook.h"
#import <objc/runtime.h>
#import <objc/message.h>

typedef IMP (^JJSwizzleImpProvider)(void);

static const char jjSwizzledDeallocKey;

// Every (class, selector) pair is swizzled exactly once. Swizzling the same pair
// twice swaps the implementations back and silently disables the guard, which is
// what happened when startGuardException was called again after stopGuardException.
static NSMutableSet<NSString *> *jjSwizzledPairs;
static NSRecursiveLock *jjSwizzleLock;

static void jj_setupSwizzleState(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        jjSwizzledPairs = [NSMutableSet set];
        jjSwizzleLock = [[NSRecursiveLock alloc] init];
        jjSwizzleLock.name = @"com.github.nattychao.JJException.swizzle";
    });
}

static NSString *jj_swizzlePairKey(Class cls, SEL selector) {
    return [NSString stringWithFormat:@"%p|%s", (void *)cls, sel_getName(selector)];
}

@interface JJSwizzleObject()
@property (nonatomic,readwrite,copy) JJSwizzleImpProvider impProviderBlock;
@property (nonatomic,readwrite,assign) SEL selector;
@end

@implementation JJSwizzleObject

- (JJSwizzleOriginalIMP)getOriginalImplementation{
    NSAssert(_impProviderBlock,nil);
    return (JJSwizzleOriginalIMP)_impProviderBlock();
}

@end

/**
 YES when `cls` implements `selector` itself rather than inheriting it.

 `class_getInstanceMethod` returns the Method of the class that actually
 implements the selector, so pointer equality with the superclass's Method is a
 reliable "not implemented here" test.
 */
static BOOL jj_implementsSelector(Class cls, SEL selector) {
    if (!cls || !selector) {
        return NO;
    }
    Method own = class_getInstanceMethod(cls, selector);
    if (!own) {
        return NO;
    }
    Class superclass = class_getSuperclass(cls);
    if (!superclass) {
        return YES;
    }
    return own != class_getInstanceMethod(superclass, selector);
}

/**
 YES when a superclass of `cls` has already been swizzled for `originSelector`.

 Must be called with jjSwizzleLock held.
 */
static BOOL jj_ancestorSwizzled(Class cls, SEL originSelector) {
    for (Class current = class_getSuperclass(cls); current; current = class_getSuperclass(current)) {
        if ([jjSwizzledPairs containsObject:jj_swizzlePairKey(current, originSelector)]) {
            return YES;
        }
    }
    return NO;
}

/**
 Core swizzle, safe against:
 - nil class / selector / method
 - method missing on the current OS
 - being called twice for the same (class, selector)
 - two threads swizzling at the same time
 - mutating a superclass IMP when swizzling a class cluster's concrete class
 - swizzling a subclass whose implementation is inherited from an already
   swizzled superclass (see the comment at the call site)
 */
static void jj_swizzleSelector(Class cls, SEL originSelector, SEL swizzleSelector, BOOL isClassMethod) {
    if (!cls || !originSelector || !swizzleSelector) {
        return;
    }

    jj_setupSwizzleState();
    [jjSwizzleLock lock];

    Class targetClass = isClassMethod ? object_getClass(cls) : cls;
    if (!targetClass) {
        [jjSwizzleLock unlock];
        return;
    }

    NSString *pairKey = jj_swizzlePairKey(targetClass, originSelector);
    if ([jjSwizzledPairs containsObject:pairKey]) {
        [jjSwizzleLock unlock];
        return;
    }

    Method originalMethod = isClassMethod
        ? class_getClassMethod(cls, originSelector)
        : class_getInstanceMethod(cls, originSelector);
    Method swizzledMethod = isClassMethod
        ? class_getClassMethod(cls, swizzleSelector)
        : class_getInstanceMethod(cls, swizzleSelector);

    // A future iOS release removing one of these selectors must never crash the
    // app at startup. The old code dereferenced a NULL Method here.
    if (!originalMethod || !swizzledMethod) {
        [jjSwizzleLock unlock];
        return;
    }

    // Inherited-from-an-already-swizzled-ancestor case.
    //
    // If targetClass does not implement originSelector itself, the method it
    // "has" is the ancestor's - and once the ancestor is swizzled that is the
    // hook, not the original. Installing a copy here would either capture the
    // hook as the "original" (which silently BYPASSES the guard for this class)
    // or call the ancestor hook twice. The hook is already reachable through
    // inheritance, so the correct action is to do nothing.
    if (!jj_implementsSelector(targetClass, originSelector) &&
        jj_ancestorSwizzled(targetClass, originSelector)) {
        [jjSwizzledPairs addObject:pairKey];
        [jjSwizzleLock unlock];
        return;
    }

    IMP originalIMP = method_getImplementation(originalMethod);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    const char *originalTypes = method_getTypeEncoding(originalMethod);
    const char *swizzledTypes = method_getTypeEncoding(swizzledMethod);

    if (!originalIMP || !swizzledIMP || !originalTypes || !swizzledTypes) {
        [jjSwizzleLock unlock];
        return;
    }

    // Give targetClass its own copy of the hook method first. Without this,
    // class_replaceMethod on a class-cluster concrete class can end up sharing
    // the hook IMP with the parent class and corrupt unrelated classes.
    class_addMethod(targetClass, swizzleSelector, swizzledIMP, swizzledTypes);

    if (class_addMethod(targetClass, originSelector, swizzledIMP, swizzledTypes)) {
        // originSelector was inherited; targetClass now has the hook.
        // Point the local hook selector at the real implementation.
        class_replaceMethod(targetClass, swizzleSelector, originalIMP, originalTypes);
    } else {
        // targetClass implements originSelector: exchange the two local methods.
        Method localOrigin = isClassMethod
            ? class_getClassMethod(cls, originSelector)
            : class_getInstanceMethod(targetClass, originSelector);
        Method localSwizzle = isClassMethod
            ? class_getClassMethod(cls, swizzleSelector)
            : class_getInstanceMethod(targetClass, swizzleSelector);
        if (localOrigin && localSwizzle) {
            method_exchangeImplementations(localOrigin, localSwizzle);
        }
    }

    [jjSwizzledPairs addObject:pairKey];
    [jjSwizzleLock unlock];
}

void swizzleClassMethod(Class cls, SEL originSelector, SEL swizzleSelector){
    jj_swizzleSelector(cls, originSelector, swizzleSelector, YES);
}

void swizzleInstanceMethod(Class cls, SEL originSelector, SEL swizzleSelector){
    jj_swizzleSelector(cls, originSelector, swizzleSelector, NO);
}

// a class doesn't need dealloc swizzled if it or a superclass has been swizzled already
static BOOL jj_requiresDeallocSwizzle(Class class)
{
    BOOL swizzled = NO;

    for ( Class currentClass = class; !swizzled && currentClass != nil; currentClass = class_getSuperclass(currentClass) ) {
        swizzled = [objc_getAssociatedObject(currentClass, &jjSwizzledDeallocKey) boolValue];
    }

    return !swizzled;
}

void jj_swizzleDeallocIfNeeded(Class class)
{
    if (!class) {
        return;
    }

    static SEL deallocSEL = NULL;
    static SEL cleanupSEL = NULL;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        deallocSEL = sel_registerName("dealloc");
        cleanupSEL = sel_registerName("jj_cleanKVO");
    });

    // The dealloc hook calls -jj_cleanKVO, which lives in a category on NSObject.
    // Classes with a different root (NSProxy and its subclasses) do not inherit
    // it, so hooking their dealloc would send an unrecognized selector from inside
    // dealloc - an instant, uncatchable crash. Skip them instead.
    if (!class_respondsToSelector(class, cleanupSEL)) {
        return;
    }

    jj_setupSwizzleState();
    // The old implementation released this lock before actually swizzling, so two
    // threads could both swizzle and the second one captured the first hook as the
    // "original" IMP -> recursive dealloc -> stack overflow.
    [jjSwizzleLock lock];

    if ( !jj_requiresDeallocSwizzle(class) ) {
        [jjSwizzleLock unlock];
        return;
    }

    Method dealloc = NULL;

    unsigned int count = 0;
    Method* method = class_copyMethodList(class, &count);
    if (method) {
        for (unsigned int i = 0; i < count; i++) {
            if (method_getName(method[i]) == deallocSEL) {
                dealloc = method[i];
                break;
            }
        }
        free(method);
    }

    const char *deallocTypes = dealloc ? method_getTypeEncoding(dealloc) : NULL;
    if (!deallocTypes) {
        Method baseDealloc = class_getInstanceMethod([NSObject class], deallocSEL);
        deallocTypes = method_getTypeEncoding(baseDealloc);
    }
    if (!deallocTypes) {
        // Never call class_addMethod with a NULL type encoding (the old code did).
        // The class is NOT marked as swizzled, so a later call can retry.
        [jjSwizzleLock unlock];
        return;
    }

    if ( dealloc == NULL ) {
        Class superclass = class_getSuperclass(class);
        if (!superclass) {
            [jjSwizzleLock unlock];
            return;
        }

        if (!class_addMethod(class, deallocSEL, imp_implementationWithBlock(^(__unsafe_unretained id self) {

            ((void(*)(id, SEL))objc_msgSend)(self, cleanupSEL);

            struct objc_super superStruct = (struct objc_super){ self, superclass };
            ((void (*)(struct objc_super*, SEL))objc_msgSendSuper)(&superStruct, deallocSEL);

        }), deallocTypes)) {
            [jjSwizzleLock unlock];
            return;
        }
    }else{
        __block IMP deallocIMP = method_setImplementation(dealloc, imp_implementationWithBlock(^(__unsafe_unretained id self) {
            ((void(*)(id, SEL))objc_msgSend)(self, cleanupSEL);

            ((void(*)(id, SEL))deallocIMP)(self, deallocSEL);
        }));
    }

    // Only mark the class once the hook is actually in place. Marking earlier
    // (as an intermediate version did) would permanently skip a class whose
    // install was aborted, silently disabling its KVO cleanup.
    objc_setAssociatedObject(class, &jjSwizzledDeallocKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [jjSwizzleLock unlock];
}


@implementation NSObject (SwizzleHook)

void __JJ_SWIZZLE_BLOCK(Class classToSwizzle,SEL selector,JJSwizzledIMPBlock impBlock){
    if (!classToSwizzle || !selector || !impBlock) {
        return;
    }

    jj_setupSwizzleState();
    [jjSwizzleLock lock];

    NSString *pairKey = jj_swizzlePairKey(classToSwizzle, selector);
    if ([jjSwizzledPairs containsObject:pairKey]) {
        [jjSwizzleLock unlock];
        return;
    }

    Method method = class_getInstanceMethod(classToSwizzle, selector);
    if (!method) {
        [jjSwizzleLock unlock];
        return;
    }

    __block IMP originalIMP = NULL;

    JJSwizzleImpProvider originalImpProvider = ^IMP{

        IMP imp = originalIMP;

        if (NULL == imp){
            Class superclass = class_getSuperclass(classToSwizzle);
            if (superclass) {
                Method superMethod = class_getInstanceMethod(superclass, selector);
                if (superMethod) {
                    imp = method_getImplementation(superMethod);
                }
            }
        }
        return imp;
    };

    JJSwizzleObject* swizzleInfo = [JJSwizzleObject new];
    swizzleInfo.selector = selector;
    swizzleInfo.impProviderBlock = originalImpProvider;

    id newIMPBlock = impBlock(swizzleInfo);

    const char* methodType = method_getTypeEncoding(method);
    if (!methodType) {
        [jjSwizzleLock unlock];
        return;
    }

    IMP newIMP = imp_implementationWithBlock(newIMPBlock);

    originalIMP = class_replaceMethod(classToSwizzle, selector, newIMP, methodType);

    [jjSwizzledPairs addObject:pairKey];
    [jjSwizzleLock unlock];
}

+ (void)jj_swizzleClassMethod:(SEL)originSelector withSwizzleMethod:(SEL)swizzleSelector{
    swizzleClassMethod(self.class, originSelector, swizzleSelector);
}

- (void)jj_swizzleInstanceMethod:(SEL)originSelector withSwizzleMethod:(SEL)swizzleSelector{
    swizzleInstanceMethod(self.class, originSelector, swizzleSelector);
}

- (void)jj_swizzleInstanceMethod:(SEL)originSelector withSwizzledBlock:(JJSwizzledIMPBlock)swizzledBlock{
    __JJ_SWIZZLE_BLOCK(self.class, originSelector, swizzledBlock);
}

@end
