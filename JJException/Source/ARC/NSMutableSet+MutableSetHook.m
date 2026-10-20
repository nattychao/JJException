//
//  NSMutableSet+MutableSetHook.m
//  JJException
//
//  Created by Jezz on 2018/11/11.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import "NSMutableSet+MutableSetHook.h"
#import "NSObject+SwizzleHook.h"
#import <objc/runtime.h>
#import "JJExceptionProxy.h"
#import "JJExceptionMacros.h"
#import "JJExceptionGuardNet.h"

JJSYNTH_DUMMY_CLASS(NSMutableSet_MutableSetHook)

@implementation NSMutableSet (MutableSetHook)

+ (void)jj_swizzleNSMutableSet{
    // Resolve the concrete class without leaking the probe instance.
    Class cls = object_getClass([NSMutableSet set]);
    if (cls) {
        swizzleInstanceMethod(cls,@selector(addObject:), @selector(hookAddObject:));
        swizzleInstanceMethod(cls,@selector(removeObject:), @selector(hookRemoveObject:));
    }

    /* Not every mutable set is __NSSetM. Measured concrete classes: CFSet bridging
       produces __NSCFSet, and NSCountedSet is a separate root. Both are mutable and
       both crash on a nil argument, so they need the same hooks. */
    Class cfSet = NSClassFromString(@"__NSCFSet");
    if (cfSet) {
        swizzleInstanceMethod(cfSet, @selector(addObject:), @selector(hookAddObject:));
        swizzleInstanceMethod(cfSet, @selector(removeObject:), @selector(hookRemoveObject:));
    }

    Class countedSet = NSClassFromString(@"NSCountedSet");
    if (countedSet) {
        swizzleInstanceMethod(countedSet, @selector(addObject:), @selector(hookAddObject:));
        swizzleInstanceMethod(countedSet, @selector(removeObject:), @selector(hookRemoveObject:));
    }
}

- (void) hookAddObject:(id)object {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookAddObject:object];
        return;
    }
    if (!object) {
        handleCrashException(JJExceptionGuardArrayContainer,@"NSSet addObject nil object");
        return;
    }
    JJ_NET_VOID(JJExceptionGuardArrayContainer, [self hookAddObject:object]);
}

- (void) hookRemoveObject:(id)object {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookRemoveObject:object];
        return;
    }
    if (!object) {
        handleCrashException(JJExceptionGuardArrayContainer,@"NSSet removeObject nil object");
        return;
    }
    JJ_NET_VOID(JJExceptionGuardArrayContainer, [self hookRemoveObject:object]);
}

@end
