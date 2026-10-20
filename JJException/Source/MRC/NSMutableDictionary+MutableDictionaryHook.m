//
//  NSMutableDictionary+MutableDictionaryHook.m
//  JJException
//
//  Created by Jezz on 2018/7/15.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import "NSMutableDictionary+MutableDictionaryHook.h"
#import "NSObject+SwizzleHook.h"
#import "JJExceptionProxy.h"
#import "JJExceptionMacros.h"
#import "JJExceptionGuardNet.h"

JJSYNTH_DUMMY_CLASS(NSMutableDictionary_MutableDictionaryHook)

@implementation NSMutableDictionary (MutableDictionaryHook)

+ (void)jj_swizzleNSMutableDictionary{
    swizzleInstanceMethod(NSClassFromString(@"__NSDictionaryM"), @selector(setObject:forKey:), @selector(hookSetObject:forKey:));
    swizzleInstanceMethod(NSClassFromString(@"__NSDictionaryM"), @selector(removeObjectForKey:), @selector(hookRemoveObjectForKey:));
    swizzleInstanceMethod(NSClassFromString(@"__NSDictionaryM"), @selector(setObject:forKeyedSubscript:), @selector(hookSetObject:forKeyedSubscript:));
}

- (void) hookSetObject:(id)object forKey:(id)key {
    if (!JJExceptionGuardEnabled(JJExceptionGuardDictionaryContainer)) {
        [self hookSetObject:object forKey:key];
        return;
    }
    if (!object || !key) {
        handleCrashException(JJExceptionGuardDictionaryContainer,[NSString stringWithFormat:@"NSMutableDictionary setObject invalid object:%@ and key:%@",object,key]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardDictionaryContainer, [self hookSetObject:object forKey:key]);
}

- (void) hookRemoveObjectForKey:(id)key {
    if (!JJExceptionGuardEnabled(JJExceptionGuardDictionaryContainer)) {
        [self hookRemoveObjectForKey:key];
        return;
    }
    if (!key) {
        handleCrashException(JJExceptionGuardDictionaryContainer,@"NSMutableDictionary removeObjectForKey nil key");
        return;
    }
    JJ_NET_VOID(JJExceptionGuardDictionaryContainer, [self hookRemoveObjectForKey:key]);
}

- (void) hookSetObject:(id)object forKeyedSubscript:(id<NSCopying>)key {
    if (!JJExceptionGuardEnabled(JJExceptionGuardDictionaryContainer)) {
        [self hookSetObject:object forKeyedSubscript:key];
        return;
    }
    // `dict[key] = nil` is documented as removal, so a nil object is legal here;
    // only a nil key is a real error.
    if (!key) {
        handleCrashException(JJExceptionGuardDictionaryContainer,[NSString stringWithFormat:@"NSMutableDictionary setObject object:%@ and forKeyedSubscript:nil",object]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardDictionaryContainer, [self hookSetObject:object forKeyedSubscript:key]);
}

@end
