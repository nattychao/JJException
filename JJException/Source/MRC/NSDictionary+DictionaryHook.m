//
//  NSDictionary+DictionaryHook.m
//  JJException
//
//  Created by Jezz on 2018/7/15.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import "NSDictionary+DictionaryHook.h"
#import "NSObject+SwizzleHook.h"
#import "JJExceptionProxy.h"
#import "JJExceptionMacros.h"

JJSYNTH_DUMMY_CLASS(NSDictionary_DictionaryHook)

@implementation NSDictionary (DictionaryHook)

+ (void)jj_swizzleNSDictionary{
    [NSDictionary jj_swizzleClassMethod:@selector(dictionaryWithObject:forKey:) withSwizzleMethod:@selector(hookDictionaryWithObject:forKey:)];
    [NSDictionary jj_swizzleClassMethod:@selector(dictionaryWithObjects:forKeys:count:) withSwizzleMethod:@selector(hookDictionaryWithObjects:forKeys:count:)];
}

+ (instancetype) hookDictionaryWithObject:(id)object forKey:(id)key
{
    if (!JJExceptionGuardEnabled(JJExceptionGuardDictionaryContainer)) {
        return [self hookDictionaryWithObject:object forKey:key];
    }
    if (object && key) {
        return [self hookDictionaryWithObject:object forKey:key];
    }
    handleCrashException(JJExceptionGuardDictionaryContainer,[NSString stringWithFormat:@"NSDictionary dictionaryWithObject invalid object:%@ and key:%@",object,key]);
    return nil;
}

+ (instancetype) hookDictionaryWithObjects:(const id [])objects forKeys:(const id [])keys count:(NSUInteger)cnt
{
    if (!JJExceptionGuardEnabled(JJExceptionGuardDictionaryContainer)) {
        return [self hookDictionaryWithObjects:objects forKeys:keys count:cnt];
    }
    if ((!objects || !keys) && cnt > 0) {
        handleCrashException(JJExceptionGuardDictionaryContainer,@"NSDictionary dictionaryWithObjects NULL object or key pointer");
        return nil;
    }

    // Fixed stack buffers instead of the original zero-length VLAs.
    id stackKeys[32];
    id stackObjects[32];
    id *ks = stackKeys;
    id *objs = stackObjects;
    BOOL heap = NO;
    if (cnt > 32) {
        ks = (id *)malloc(sizeof(id) * cnt);
        objs = (id *)malloc(sizeof(id) * cnt);
        if (!ks || !objs) {
            if (ks) free(ks);
            if (objs) free(objs);
            handleCrashException(JJExceptionGuardDictionaryContainer,@"NSDictionary dictionaryWithObjects malloc failed");
            return nil;
        }
        heap = YES;
    }

    NSUInteger index = 0;
    for (NSUInteger i = 0; i < cnt; i++) {
        if (keys[i] && objects[i]) {
            ks[index] = keys[i];
            objs[index] = objects[i];
            index++;
        }else{
            handleCrashException(JJExceptionGuardDictionaryContainer,[NSString stringWithFormat:@"NSDictionary dictionaryWithObjects invalid keys:%@ and object:%@",keys[i],objects[i]]);
        }
    }
    id result = [self hookDictionaryWithObjects:objs forKeys:ks count:index];
    if (heap) {
        free(ks);
        free(objs);
    }
    return result;
}

@end
