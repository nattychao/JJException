//
//  NSSet+SetHook.m
//  JJException
//
//  Created by Jezz on 2018/11/11.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import "NSSet+SetHook.h"
#import "NSObject+SwizzleHook.h"
#import "JJExceptionProxy.h"
#import "JJExceptionMacros.h"
#import "JJExceptionGuardNet.h"

JJSYNTH_DUMMY_CLASS(NSSet_SetHook)

@implementation NSSet (SetHook)

+ (void)jj_swizzleNSSet{
    [NSSet jj_swizzleClassMethod:@selector(setWithObject:) withSwizzleMethod:@selector(hookSetWithObject:)];
}

+ (instancetype)hookSetWithObject:(id)object{
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        return [self hookSetWithObject:object];
    }
    if (!object){
        handleCrashException(JJExceptionGuardArrayContainer,@"NSSet setWithObject nil object");
        return nil;
    }
    return JJ_NET_SCALAR(id, JJExceptionGuardArrayContainer, nil, [self hookSetWithObject:object]);
}

@end
