//
//  NSNotificationCenter+ClearNotification.m
//  JJException
//
//  Created by Jezz on 2018/9/6.
//  Copyright © 2018年 Jezz. All rights reserved.
//
//  Rewritten for the nattychao fork.
//
//  Upstream registered the cleanup against `[NSNotificationCenter defaultCenter]`
//  regardless of which center the observer actually registered with. Any observer
//  on a custom center was therefore never removed (and the default center was
//  asked to remove an observer it never had). This version captures the real
//  center weakly and removes the observer from that instance.
//
//  Note: since iOS 9 NSNotificationCenter keeps observers weakly and unregisters
//  them automatically on dealloc, so this is a defence-in-depth guard rather than
//  the only thing standing between the app and a crash.
//

#import "NSNotificationCenter+ClearNotification.h"
#import "NSObject+SwizzleHook.h"
#import "NSObject+DeallocBlock.h"
#import "JJExceptionMacros.h"
#import "JJExceptionProxy.h"
#import "JJWeakObjectBox.h"
#import <objc/runtime.h>

JJSYNTH_DUMMY_CLASS(NSNotificationCenter_ClearNotification)

@implementation NSNotificationCenter (ClearNotification)

+ (void)jj_swizzleNSNotificationCenter{
    [self jj_swizzleInstanceMethod:@selector(addObserver:selector:name:object:) withSwizzledBlock:^id(JJSwizzleObject *swizzleInfo) {
        return ^(__unsafe_unretained id self,id observer,SEL aSelector,NSString* aName,id anObject){
            [self processAddObserver:observer selector:aSelector name:aName object:anObject swizzleInfo:swizzleInfo];
        };
    }];
}

- (void)processAddObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject swizzleInfo:(JJSwizzleObject*)swizzleInfo{

    if (!JJExceptionGuardEnabled(JJExceptionGuardNSNotificationCenter)) {
        void(*originIMP)(__unsafe_unretained id,SEL,id,SEL,NSString*,id);
        originIMP = (__typeof(originIMP))[swizzleInfo getOriginalImplementation];
        if (originIMP != NULL) {
            originIMP(self,swizzleInfo.selector,observer,aSelector,aName,anObject);
        }
        return;
    }

    if (!observer) {
        handleCrashException(JJExceptionGuardNSNotificationCenter, @"NSNotificationCenter addObserver nil observer");
        return;
    }
    if (!aSelector) {
        // Foundation raises NSInvalidArgumentException for a NULL selector; a
        // crash here would happen even before the notification is ever posted.
        handleCrashException(JJExceptionGuardNSNotificationCenter, @"NSNotificationCenter addObserver NULL selector");
        return;
    }

    if ([observer isKindOfClass:NSObject.class]) {
        // The center must be held weakly: the observer may outlive it.
        JJWeakObjectBox *centerBox = [[JJWeakObjectBox alloc] initWithObject:self];
        // The observer must NOT be captured strongly: the block is stored on the
        // observer itself, so a strong capture would be a retain cycle and the
        // observer would never deallocate (a leak the upstream version avoided
        // with __unsafe_unretained). The block only runs from the observer's own
        // dealloc, where the pointer is still a valid identity.
        __unsafe_unretained id unretainedObserver = observer;
        [observer jj_deallocBlock:^{
            NSNotificationCenter *center = centerBox.object;
            if (center && unretainedObserver) {
                [center removeObserver:unretainedObserver];
            }
        }];
    }

    void(*originIMP)(__unsafe_unretained id,SEL,id,SEL,NSString*,id);
    originIMP = (__typeof(originIMP))[swizzleInfo getOriginalImplementation];
    if (originIMP != NULL) {
        @try {
            originIMP(self,swizzleInfo.selector,observer,aSelector,aName,anObject);
        } @catch (NSException *exception) {
            handleCrashException(JJExceptionGuardNSNotificationCenter,
                                 [NSString stringWithFormat:@"NSNotificationCenter addObserver failed: %@", exception.reason]);
        }
    }
}

@end
