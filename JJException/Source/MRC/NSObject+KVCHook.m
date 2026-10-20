//
//  NSObject+KVCHook.m
//  JJException
//
//  Setter-side KVC guard.
//
//  These five entry points were the biggest remaining hole compared to
//  chenfanfang/AvoidCrash: none of them existed in upstream JJException, and every
//  one of them throws on ordinary bad input (measured on iOS 18.6 / 27.0 / 27.1):
//
//    [obj setValue:v forKey:nil]                          NSInvalidArgumentException
//    [obj setValue:v forKeyPath:nil]                      NSInvalidArgumentException
//    [obj setValue:v forKey:@"noSuchProperty"]            NSUnknownKeyException
//    [obj setValuesForKeysWithDictionary:@{...}]          NSUnknownKeyException
//    [dict setValue:v forKey:nil]                         NSInvalidArgumentException
//
//  Policy: these are setter calls, so "cannot apply" is reported and dropped. A
//  dropped write is visible in the log; a crash is not.
//

#import "NSObject+KVCHook.h"
#import "NSObject+SwizzleHook.h"
#import "JJExceptionProxy.h"
#import "JJExceptionMacros.h"
#import "JJExceptionGuardNet.h"

JJSYNTH_DUMMY_CLASS(NSObject_KVCHook)

@implementation NSObject (KVCHook)

+ (void)jj_swizzleKVC{
    swizzleInstanceMethod([self class], @selector(setValue:forKey:), @selector(hookSetValue:forKey:));
    swizzleInstanceMethod([self class], @selector(setValue:forKeyPath:), @selector(hookSetValue:forKeyPath:));
    swizzleInstanceMethod([self class], @selector(setValue:forUndefinedKey:), @selector(hookSetValue:forUndefinedKey:));
    swizzleInstanceMethod([self class], @selector(setValuesForKeysWithDictionary:), @selector(hookSetValuesForKeysWithDictionary:));
}

- (void)hookSetValue:(id)value forKey:(NSString *)key {
    if (!JJExceptionGuardEnabled(JJExceptionGuardKVCCrash)
        && !JJExceptionGuardEnabled(JJExceptionGuardDictionaryContainer)) {
        [self hookSetValue:value forKey:key];
        return;
    }
    if (!key) {
        handleCrashException(JJExceptionGuardKVCCrash,
                             [NSString stringWithFormat:@"KVC setValue:forKey: nil key on class:%@", NSStringFromClass([self class])]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardKVCCrash, [self hookSetValue:value forKey:key]);
}

- (void)hookSetValue:(id)value forKeyPath:(NSString *)keyPath {
    if (!JJExceptionGuardEnabled(JJExceptionGuardKVCCrash)) {
        [self hookSetValue:value forKeyPath:keyPath];
        return;
    }
    if (!keyPath) {
        handleCrashException(JJExceptionGuardKVCCrash,
                             [NSString stringWithFormat:@"KVC setValue:forKeyPath: nil keyPath on class:%@", NSStringFromClass([self class])]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardKVCCrash, [self hookSetValue:value forKeyPath:keyPath]);
}

- (void)hookSetValue:(id)value forUndefinedKey:(NSString *)key {
    if (!JJExceptionGuardEnabled(JJExceptionGuardKVCCrash)) {
        [self hookSetValue:value forUndefinedKey:key];
        return;
    }
    // Reaching forUndefinedKey: means the property genuinely does not exist. Report
    // it instead of throwing, which is exactly what the default implementation
    // would do (raise NSUnknownKeyException).
    handleCrashException(JJExceptionGuardKVCCrash,
                         [NSString stringWithFormat:@"KVC unknown key:%@ on class:%@ value:%@",
                          key, NSStringFromClass([self class]), value]);
}

- (void)hookSetValuesForKeysWithDictionary:(NSDictionary<NSString *, id> *)keyedValues {
    if (!JJExceptionGuardEnabled(JJExceptionGuardKVCCrash)) {
        [self hookSetValuesForKeysWithDictionary:keyedValues];
        return;
    }
    if (!keyedValues) {
        handleCrashException(JJExceptionGuardKVCCrash,@"KVC setValuesForKeysWithDictionary: nil dictionary");
        return;
    }
    JJ_NET_VOID(JJExceptionGuardKVCCrash, [self hookSetValuesForKeysWithDictionary:keyedValues]);
}

@end
