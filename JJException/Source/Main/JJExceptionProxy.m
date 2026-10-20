//
//  JJExceptionProxy.m
//  JJException
//
//  Created by Jezz on 2018/7/22.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import "JJExceptionProxy.h"
#import <mach-o/dyld.h>
#import <objc/runtime.h>

__attribute__((overloadable)) void handleCrashException(NSString* exceptionMessage){
    [[JJExceptionProxy shareExceptionProxy] handleCrashException:exceptionMessage extraInfo:@{}];
}

__attribute__((overloadable)) void handleCrashException(NSString* exceptionMessage,NSDictionary* extraInfo){
    [[JJExceptionProxy shareExceptionProxy] handleCrashException:exceptionMessage extraInfo:extraInfo];
}

__attribute__((overloadable)) void handleCrashException(JJExceptionGuardCategory exceptionCategory, NSString* exceptionMessage,NSDictionary* extraInfo){
    [[JJExceptionProxy shareExceptionProxy] handleCrashException:exceptionMessage exceptionCategory:exceptionCategory extraInfo:extraInfo];
}

__attribute__((overloadable)) void handleCrashException(JJExceptionGuardCategory exceptionCategory, NSString* exceptionMessage){
    [[JJExceptionProxy shareExceptionProxy] handleCrashException:exceptionMessage exceptionCategory:exceptionCategory extraInfo:nil];
}

/**
 Get application base address,the application different base address after started
 
 @return base address
 */
uintptr_t get_load_address(void) {
    const struct mach_header *exe_header = NULL;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const struct mach_header *header = _dyld_get_image_header(i);
        if (header->filetype == MH_EXECUTE) {
            exe_header = header;
            break;
        }
    }
    return (uintptr_t)exe_header;
}

/**
 Address Offset

 @return slide address
 */
uintptr_t get_slide_address(void) {
    uintptr_t vmaddr_slide = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const struct mach_header *header = _dyld_get_image_header(i);
        if (header->filetype == MH_EXECUTE) {
            vmaddr_slide = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }
    
    return (uintptr_t)vmaddr_slide;
}

@interface JJExceptionProxy(){
    NSMutableSet* _currentClassesSet;
    NSMutableSet* _blackClassesSet;
    NSInteger _currentClassSize;
    dispatch_semaphore_t _classArrayLock;//Protect _blackClassesSet and _currentClassesSet atomic
    dispatch_semaphore_t _swizzleLock;//Protect swizzle atomic
}

@end

@implementation JJExceptionProxy

+(instancetype)shareExceptionProxy{
    static dispatch_once_t onceToken;
    static id exceptionProxy;
    dispatch_once(&onceToken, ^{
        exceptionProxy = [[self alloc] init];
    });
    return exceptionProxy;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _blackClassesSet = [NSMutableSet new];
        _currentClassesSet = [NSMutableSet new];
        _currentClassSize = 0;
        _classArrayLock = dispatch_semaphore_create(1);
        _swizzleLock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)handleCrashException:(NSString *)exceptionMessage exceptionCategory:(JJExceptionGuardCategory)exceptionCategory extraInfo:(NSDictionary *)info{
    if (!exceptionMessage) {
        return;
    }

    // Re-entrancy guard. Reporting builds strings and calls the delegate; if either
    // path trips the same guard again (e.g. a delegate that appends to a string
    // with an out-of-range substring), the process would recurse until the stack
    // overflows. One report per thread at a time is enough.
    static NSString *const reentryKey = @"com.github.nattychao.JJException.reporting";
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    if ([threadDictionary[reentryKey] boolValue]) {
        return;
    }
    threadDictionary[reentryKey] = @YES;
    @try {
        [self jj_reportExceptionMessage:exceptionMessage
                     exceptionCategory:exceptionCategory
                               extraInfo:info];
    } @finally {
        [threadDictionary removeObjectForKey:reentryKey];
    }
}

/// First frame in the call stack that belongs to the host app rather than to the
/// system or to this library.
///
/// Borrowed from chenfanfang/AvoidCrash: pointing at "your app's -[Class method]"
/// is far more useful than a 40-frame dump that is mostly Foundation internals.
static NSString *jj_mainCallStackSymbol(NSArray<NSString *> *callStackSymbols) {
    if (callStackSymbols.count == 0) {
        return nil;
    }
    // -[Class method] / +[Class method]
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"[-\\+]\\[.+\\]"
                                                          options:0
                                                            error:NULL];
    });
    if (!regex) {
        return nil;
    }

    // Skip the frames that are this library's own plumbing. Match the specific
    // internal symbols, NOT the substring "JJException": host apps very often have
    // "JJException" in their own binary name, which would discard every frame.
    static NSArray<NSString *> *internalMarkers;
    static dispatch_once_t markersOnce;
    dispatch_once(&markersOnce, ^{
        internalMarkers = @[@"JJExceptionProxy",
                            @"jj_reportExceptionMessage",
                            @"handleCrashException",
                            @"jj_swizzle",
                            @"hookObject",
                            @"hookSubstring",
                            @"hookSetObject"];
    });

    // System suffixes that are never "the app's own code".
    static NSArray<NSString *> *systemPrefixes;
    static dispatch_once_t prefixesOnce;
    dispatch_once(&prefixesOnce, ^{
        systemPrefixes = @[@"__", @"NS", @"UI", @"CA", @"CF", @"CG", @"_", @"Swift",
                           @"Foundation", @"CoreFoundation", @"dyld", @"libsystem"];
    });

    for (NSUInteger index = 0; index < callStackSymbols.count; index++) {
        NSString *symbol = callStackSymbols[index];

        BOOL isInternal = NO;
        for (NSString *marker in internalMarkers) {
            if ([symbol containsString:marker]) {
                isInternal = YES;
                break;
            }
        }
        if (isInternal) {
            continue;
        }

        NSRange match = [regex rangeOfFirstMatchInString:symbol
                                                 options:0
                                                   range:NSMakeRange(0, symbol.length)];
        if (match.location == NSNotFound) {
            continue;
        }
        NSString *frame = [symbol substringWithRange:match];

        // Extract the class name from "[ClassName method]".
        NSRange open = [frame rangeOfString:@"["];
        if (open.location == NSNotFound) {
            continue;
        }
        NSString *afterBracket = [frame substringFromIndex:NSMaxRange(open)];
        NSString *className = [[afterBracket componentsSeparatedByString:@" "] firstObject];
        if ([className hasSuffix:@")"]) {
            continue;   // category / block frame, e.g. NSMutableArray(MutableArrayHook)
        }

        BOOL isSystem = NO;
        for (NSString *prefix in systemPrefixes) {
            if ([className hasPrefix:prefix]) {
                isSystem = YES;
                break;
            }
        }
        if (isSystem) {
            continue;
        }

        // Prefer a frame that belongs to the main bundle, but accept any
        // non-system frame: with Xcode's debug-dylib layout the app's classes can
        // report a bundle different from mainBundle.
        @try {
            Class cls = NSClassFromString(className);
            if (cls && [NSBundle bundleForClass:cls] == [NSBundle mainBundle]) {
                return frame;
            }
        } @catch (NSException *exception) {
            // Ignore: a bad frame must never break reporting.
        }

        // Fallback: first plausible non-system frame we saw.
        return frame;
    }
    return nil;
}

- (void)jj_reportExceptionMessage:(NSString *)exceptionMessage
                exceptionCategory:(JJExceptionGuardCategory)exceptionCategory
                          extraInfo:(NSDictionary *)info {
    NSArray* callStack = nil;
    @try {
        callStack = [NSThread callStackSymbols];
    } @catch (NSException *exception) {
        callStack = @[];
    }
    NSString* callStackString = [NSString stringWithFormat:@"%@",callStack ?: @[]];

    uintptr_t loadAddress =  get_load_address();
    uintptr_t slideAddress =  get_slide_address();

    NSString *location = jj_mainCallStackSymbol(callStack);
    NSString *exceptionResult = location.length > 0
        ? [NSString stringWithFormat:@"%ld\n%ld\n%@\nError Place:%@\n%@",
                                     loadAddress, slideAddress, exceptionMessage, location, callStackString]
        : [NSString stringWithFormat:@"%ld\n%ld\n%@\n%@",
                                     loadAddress, slideAddress, exceptionMessage, callStackString];

    // The delegate is app code. It must never be able to turn a recovered
    // exception into a crash of the reporting path.
    @try {
        if ([self.delegate respondsToSelector:@selector(handleCrashException:extraInfo:)]){
            [self.delegate handleCrashException:exceptionResult extraInfo:info];
        }

        if ([self.delegate respondsToSelector:@selector(handleCrashException:exceptionCategory:extraInfo:)]) {
            [self.delegate handleCrashException:exceptionResult exceptionCategory:exceptionCategory extraInfo:info];
        }
    } @catch (NSException *exception) {
        NSLog(@"[JJException] reporting delegate threw: %@", exception);
    }

#ifdef DEBUG
    NSLog(@"================================JJException Start==================================");
    NSLog(@"JJException Type:%ld",(long)exceptionCategory);
    NSLog(@"JJException Description:%@",exceptionMessage);
    NSLog(@"JJException Extra info:%@",info);
    NSLog(@"JJException CallStack:%@",callStack);
    NSLog(@"================================JJException End====================================");
    if (self.exceptionWhenTerminate) {
        NSAssert(NO, @"");
    }
#endif
}

- (void)handleCrashException:(NSString *)exceptionMessage extraInfo:(nullable NSDictionary *)info{
    [self handleCrashException:exceptionMessage exceptionCategory:JJExceptionGuardNone extraInfo:info];
}

- (void)setIsProtectException:(BOOL)isProtectException{
    dispatch_semaphore_wait(_swizzleLock, DISPATCH_TIME_FOREVER);
    if (_isProtectException != isProtectException) {
        _isProtectException = isProtectException;
        if (isProtectException) {
            [self jj_installSwizzlesForEnabledCategories];
        }
    }
    dispatch_semaphore_signal(_swizzleLock);
}

/// Installs the hooks for every category currently in the mask.
///
/// Called both when protection turns on and whenever the mask changes while
/// protection is already active. Every hook is idempotent (see
/// NSObject+SwizzleHook.m), so calling this repeatedly is safe and is what makes
/// `configExceptionCategory:` take effect without restarting the app.
- (void)jj_installSwizzlesForEnabledCategories {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wundeclared-selector"

    if(self.exceptionGuardCategory & JJExceptionGuardArrayContainer){
        [NSArray performSelector:@selector(jj_swizzleNSArray)];
        [NSMutableArray performSelector:@selector(jj_swizzleNSMutableArray)];
        [NSSet performSelector:@selector(jj_swizzleNSSet)];
        [NSMutableSet performSelector:@selector(jj_swizzleNSMutableSet)];
    }
    if(self.exceptionGuardCategory & JJExceptionGuardDictionaryContainer){
        [NSDictionary performSelector:@selector(jj_swizzleNSDictionary)];
        [NSMutableDictionary performSelector:@selector(jj_swizzleNSMutableDictionary)];
    }
    if(self.exceptionGuardCategory & JJExceptionGuardUnrecognizedSelector){
        [NSObject performSelector:@selector(jj_swizzleUnrecognizedSelector)];
    }

    if (self.exceptionGuardCategory & JJExceptionGuardKVOCrash) {
        [NSObject performSelector:@selector(jj_swizzleKVOCrash)];
    }

    if (self.exceptionGuardCategory & JJExceptionGuardNSTimer) {
        [NSTimer performSelector:@selector(jj_swizzleNSTimer)];
    }

    if (self.exceptionGuardCategory & JJExceptionGuardNSNotificationCenter) {
        [NSNotificationCenter performSelector:@selector(jj_swizzleNSNotificationCenter)];
    }

    if (self.exceptionGuardCategory & JJExceptionGuardNSStringContainer) {
        [NSString performSelector:@selector(jj_swizzleNSString)];
        [NSMutableString performSelector:@selector(jj_swizzleNSMutableString)];
        [NSAttributedString performSelector:@selector(jj_swizzleNSAttributedString)];
        [NSMutableAttributedString performSelector:@selector(jj_swizzleNSMutableAttributedString)];
    }

    if (self.exceptionGuardCategory & JJExceptionGuardKVCCrash) {
        [NSObject performSelector:@selector(jj_swizzleKVC)];
    }
    #pragma clang diagnostic pop
}

- (void)setExceptionGuardCategory:(JJExceptionGuardCategory)exceptionGuardCategory{
    if (_exceptionGuardCategory != exceptionGuardCategory) {
        _exceptionGuardCategory = exceptionGuardCategory;
    }
    // Enabling a category at runtime must install its hooks now; otherwise the
    // hook would only appear after the next stop/start cycle. Installing is
    // idempotent, so this is a no-op when nothing new was requested.
    if (self.isProtectException) {
        dispatch_semaphore_wait(_swizzleLock, DISPATCH_TIME_FOREVER);
        [self jj_installSwizzlesForEnabledCategories];
        dispatch_semaphore_signal(_swizzleLock);
    }
}

@end

BOOL JJExceptionGuardEnabled(JJExceptionGuardCategory category) {
    // JJExceptionGuardNone is used by the internal "report only" API, which must
    // always be delivered regardless of which categories are enabled.
    if (category == JJExceptionGuardNone) {
        return YES;
    }
    JJExceptionProxy *proxy = [JJExceptionProxy shareExceptionProxy];
    if (!proxy.isProtectException) {
        return NO;
    }
    return (proxy.exceptionGuardCategory & category) != 0;
}
