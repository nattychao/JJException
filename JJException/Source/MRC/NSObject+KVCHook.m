//
//  NSObject+KVCHook.m
//  JJException
//
//  Setter-side KVC guard.
//
//  These entry points were the biggest remaining hole compared to
//  chenfanfang/AvoidCrash: none of them existed in upstream JJException, and every
//  one of them throws on ordinary bad input (measured on iOS 18.6 / 27.0 / 27.1):
//
//    [obj setValue:v forKey:nil]                          NSInvalidArgumentException
//    [obj setValue:v forKeyPath:nil]                      NSInvalidArgumentException
//    [obj setValue:v forKey:@"noSuchProperty"]            NSUnknownKeyException
//    [obj setValuesForKeysWithDictionary:@{...}]          NSUnknownKeyException
//    [dict setValue:v forKey:nil]                         NSInvalidArgumentException
//
//  Note on the last one: NSMutableDictionary OVERRIDES -setValue:forKey:, so
//  swizzling NSObject does not reach it. It has to be hooked on __NSDictionaryM as
//  well, otherwise enabling only the KVC category leaves that crash point open.
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

+ (void)jj_swizzleKVCContainerOverrides{
    /* -setValue:forKey: is overridden by NSMutableDictionary and NSArray, so the
       NSObject-level hook above never sees their calls. Measured owner map on
       18.6/27.0/27.1:
           NSObject        -> NSObject
           __NSDictionaryM -> NSMutableDictionary   (not __NSDictionaryM)
           __NSDictionaryI -> NSObject
           __NSArrayM      -> NSArray               (not __NSArrayM)

       These need DISTINCT hook selectors. If the same selector were used, the
       already-swizzled NSObject would satisfy class_getInstanceMethod for it and the
       exchange here would install NSObject's original IMP - silently undoing the
       guard on the container (verified: the hook IMP became NSObject's). */
    Class mutableDictionary = NSClassFromString(@"NSMutableDictionary");
    if (mutableDictionary) {
        swizzleInstanceMethod(mutableDictionary, @selector(setValue:forKey:), @selector(hookDictSetValue:forKey:));
    }
    Class array = NSClassFromString(@"NSArray");
    if (array) {
        swizzleInstanceMethod(array, @selector(setValue:forKey:), @selector(hookArraySetValue:forKey:));
    }
}

/// Hook used for NSMutableDictionary's own -setValue:forKey:.
- (void)hookDictSetValue:(id)value forKey:(NSString *)key {
    if (!JJExceptionGuardEnabled(JJExceptionGuardKVCCrash)) {
        [self hookDictSetValue:value forKey:key];
        return;
    }
    if (!key) {
        handleCrashException(JJExceptionGuardKVCCrash,
                             [NSString stringWithFormat:@"KVC setValue:forKey: nil key on class:%@", NSStringFromClass([self class])]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardKVCCrash, [self hookDictSetValue:value forKey:key]);
}

/// Hook used for NSArray's own -setValue:forKey:.
- (void)hookArraySetValue:(id)value forKey:(NSString *)key {
    if (!JJExceptionGuardEnabled(JJExceptionGuardKVCCrash)) {
        [self hookArraySetValue:value forKey:key];
        return;
    }
    if (!key) {
        handleCrashException(JJExceptionGuardKVCCrash,
                             [NSString stringWithFormat:@"KVC setValue:forKey: nil key on class:%@", NSStringFromClass([self class])]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardKVCCrash, [self hookArraySetValue:value forKey:key]);
}

- (void)hookSetValue:(id)value forKey:(NSString *)key {
    if (!JJExceptionGuardEnabled(JJExceptionGuardKVCCrash)) {
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
    // it instead of throwing (the default implementation raises NSUnknownKeyException).
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
