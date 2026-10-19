//
//  NSTimer+CleanTimer.m
//  JJException
//
//  Created by Jezz on 2018/9/4.
//  Copyright © 2018年 Jezz. All rights reserved.
//
//  Rewritten for the nattychao fork.
//
//  What upstream did: replaced the real target with a `TimerObject` proxy and made
//  that proxy hold the target weakly. That silently converts NSTimer's documented
//  strong reference into a weak one. NSTimer retaining its target means a live
//  target can never be messaged after death, so the proxy never prevented a crash;
//  it only turned a retain cycle (leak) into a timer that stops firing, and it
//  broke third-party SDKs (JPush and similar) whose timer target is owned solely
//  by the timer.
//
//  This version keeps Foundation's ownership semantics and guards the inputs that
//  actually crash the process:
//    - a NULL selector: SIGBUS inside CFRunLoopTimerCreate before any ObjC stack
//      exists, so it cannot be caught afterwards. Measured on iOS 18.6.
//    - a target that does not implement the selector: unrecognized selector on the
//      first fire.
//    - a nil target with a non-nil selector: cannot fire, always a caller bug.
//

#import <objc/runtime.h>
#import <objc/message.h>

#import "NSTimer+CleanTimer.h"
#import "NSObject+SwizzleHook.h"
#import "JJExceptionProxy.h"

@implementation NSTimer (CleanTimer)

+ (void)jj_swizzleNSTimer{
    swizzleClassMethod([self class], @selector(scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:), @selector(hookScheduledTimerWithTimeInterval:target:selector:userInfo:repeats:));
    swizzleClassMethod([self class], @selector(timerWithTimeInterval:target:selector:userInfo:repeats:), @selector(hookTimerWithTimeInterval:target:selector:userInfo:repeats:));
}

/// YES when the arguments are safe to forward to Foundation.
+ (BOOL)jj_validateTimerTarget:(id)aTarget selector:(SEL)aSelector context:(const char *)context {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSTimer)) {
        return YES;
    }
    if (!aSelector) {
        handleCrashException(JJExceptionGuardNSTimer,
                             [NSString stringWithFormat:@"NSTimer %s selector is NULL (would SIGBUS)", context]);
        return NO;
    }
    if (!aTarget) {
        handleCrashException(JJExceptionGuardNSTimer,
                             [NSString stringWithFormat:@"NSTimer %s target is nil, timer can never fire", context]);
        return NO;
    }
    if (![aTarget respondsToSelector:aSelector]) {
        handleCrashException(JJExceptionGuardNSTimer,
                             [NSString stringWithFormat:@"NSTimer %s target:%@ does not respond to %@",
                              context, NSStringFromClass([aTarget class]), NSStringFromSelector(aSelector)]);
        return NO;
    }
    return YES;
}

+ (NSTimer*)hookScheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo{
    if (![self jj_validateTimerTarget:aTarget selector:aSelector context:"scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:"]) {
        return nil;
    }
    return [self hookScheduledTimerWithTimeInterval:ti target:aTarget selector:aSelector userInfo:userInfo repeats:yesOrNo];
}

+ (NSTimer*)hookTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo{
    if (![self jj_validateTimerTarget:aTarget selector:aSelector context:"timerWithTimeInterval:target:selector:userInfo:repeats:"]) {
        return nil;
    }
    return [self hookTimerWithTimeInterval:ti target:aTarget selector:aSelector userInfo:userInfo repeats:yesOrNo];
}

@end
