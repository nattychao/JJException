//
//  NSArray+ArrayHook.m
//  JJException
//
//  Created by Jezz on 2018/7/11.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import "NSArray+ArrayHook.h"
#import "NSObject+SwizzleHook.h"
#import "JJExceptionProxy.h"
#import "JJExceptionMacros.h"
#import "JJExceptionRange.h"

JJSYNTH_DUMMY_CLASS(NSArray_ArrayHook)

@implementation NSArray (ArrayHook)

+ (void)jj_swizzleNSArray{
    [NSArray jj_swizzleClassMethod:@selector(arrayWithObject:) withSwizzleMethod:@selector(hookArrayWithObject:)];
    [NSArray jj_swizzleClassMethod:@selector(arrayWithObjects:count:) withSwizzleMethod:@selector(hookArrayWithObjects:count:)];

    /* __NSArray0 */
    swizzleInstanceMethod(NSClassFromString(@"__NSArray0"), @selector(objectAtIndex:), @selector(hookObjectAtIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArray0"), @selector(subarrayWithRange:), @selector(hookSubarrayWithRange:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArray0"), @selector(objectAtIndexedSubscript:), @selector(hookObjectAtIndexedSubscript:));

    /* __NSArrayI */
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayI"), @selector(objectAtIndex:), @selector(hookObjectAtIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayI"), @selector(subarrayWithRange:), @selector(hookSubarrayWithRange:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayI"), @selector(objectAtIndexedSubscript:), @selector(hookObjectAtIndexedSubscript:));

    /* __NSArrayI_Transfer */
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayI_Transfer"), @selector(objectAtIndex:), @selector(hookObjectAtIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayI_Transfer"), @selector(subarrayWithRange:), @selector(hookSubarrayWithRange:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayI_Transfer"), @selector(objectAtIndexedSubscript:), @selector(hookObjectAtIndexedSubscript:));

    /* above iOS10  __NSSingleObjectArrayI */
    swizzleInstanceMethod(NSClassFromString(@"__NSSingleObjectArrayI"), @selector(objectAtIndex:), @selector(hookObjectAtIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSSingleObjectArrayI"), @selector(subarrayWithRange:), @selector(hookSubarrayWithRange:));
    swizzleInstanceMethod(NSClassFromString(@"__NSSingleObjectArrayI"), @selector(objectAtIndexedSubscript:), @selector(hookObjectAtIndexedSubscript:));

    /* __NSFrozenArrayM */
    swizzleInstanceMethod(NSClassFromString(@"__NSFrozenArrayM"), @selector(objectAtIndex:), @selector(hookObjectAtIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSFrozenArrayM"), @selector(subarrayWithRange:), @selector(hookSubarrayWithRange:));
    swizzleInstanceMethod(NSClassFromString(@"__NSFrozenArrayM"), @selector(objectAtIndexedSubscript:), @selector(hookObjectAtIndexedSubscript:));

    /* __NSArrayReversed */
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayReversed"), @selector(objectAtIndex:), @selector(hookObjectAtIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayReversed"), @selector(subarrayWithRange:), @selector(hookSubarrayWithRange:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayReversed"), @selector(objectAtIndexedSubscript:), @selector(hookObjectAtIndexedSubscript:));

    /* NSConstantArray: array literals made only of constants (@[@"a", @"b"]). These
       do NOT go through arrayWithObjects: and were completely unguarded before. */
    swizzleInstanceMethod(NSClassFromString(@"NSConstantArray"), @selector(objectAtIndex:), @selector(hookObjectAtIndex:));
    swizzleInstanceMethod(NSClassFromString(@"NSConstantArray"), @selector(subarrayWithRange:), @selector(hookSubarrayWithRange:));
    swizzleInstanceMethod(NSClassFromString(@"NSConstantArray"), @selector(objectAtIndexedSubscript:), @selector(hookObjectAtIndexedSubscript:));
}

+ (instancetype) hookArrayWithObject:(id)anObject
{
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        return [self hookArrayWithObject:anObject];
    }
    if (anObject) {
        return [self hookArrayWithObject:anObject];
    }
    handleCrashException(JJExceptionGuardArrayContainer,@"NSArray arrayWithObject object is nil");
    return nil;
}

- (id) hookObjectAtIndex:(NSUInteger)index {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        return [self hookObjectAtIndex:index];
    }
    if (index < self.count) {
        return [self hookObjectAtIndex:index];
    }
    handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSArray objectAtIndex invalid index:%lu total:%lu",(unsigned long)index,(unsigned long)self.count]);
    return nil;
}

- (id) hookObjectAtIndexedSubscript:(NSInteger)index {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        return [self hookObjectAtIndexedSubscript:index];
    }
    NSUInteger unsignedIndex = (NSUInteger)index;
    if (unsignedIndex < self.count) {
        return [self hookObjectAtIndexedSubscript:(NSInteger)unsignedIndex];
    }
    handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSArray objectAtIndexedSubscript invalid index:%lu total:%lu",(unsigned long)unsignedIndex,(unsigned long)self.count]);
    return nil;
}

- (NSArray *)hookSubarrayWithRange:(NSRange)range
{
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        return [self hookSubarrayWithRange:range];
    }
    if (JJExceptionIsValidRange(range, self.count)) {
        return [self hookSubarrayWithRange:range];
    }
    if (range.location < self.count) {
        // Keep upstream behaviour (truncate), but report it: silently returning a
        // shorter array hides the caller's bug.
        NSRange clamped = JJExceptionClampRange(range, self.count);
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSArray subarrayWithRange invalid range location:%lu length:%lu, clamped to location:%lu length:%lu",
                                                             (unsigned long)range.location,(unsigned long)range.length,
                                                             (unsigned long)clamped.location,(unsigned long)clamped.length]);
        return [self hookSubarrayWithRange:clamped];
    }
    handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSArray subarrayWithRange invalid range location:%lu length:%lu",(unsigned long)range.location,(unsigned long)range.length]);
    return nil;
}

+ (instancetype)hookArrayWithObjects:(const id [])objects count:(NSUInteger)cnt
{
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        return [self hookArrayWithObjects:objects count:cnt];
    }
    if (!objects && cnt > 0) {
        handleCrashException(JJExceptionGuardArrayContainer,@"NSArray arrayWithObjects NULL objects pointer");
        return nil;
    }

    // Fixed stack buffer avoids the original zero-length VLA (undefined behaviour
    // when cnt == 0) and keeps the common path allocation free.
    id stackObjects[32];
    id *objs = stackObjects;
    if (cnt > 32) {
        objs = (id *)malloc(sizeof(id) * cnt);
        if (!objs) {
            handleCrashException(JJExceptionGuardArrayContainer,@"NSArray arrayWithObjects malloc failed");
            return nil;
        }
    }

    NSUInteger index = 0;
    for (NSUInteger i = 0; i < cnt; i++) {
        if (objects[i]) {
            objs[index++] = objects[i];
        }else{
            handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSArray arrayWithObjects invalid index object:%lu total:%lu",(unsigned long)i,(unsigned long)cnt]);
        }
    }
    id result = [self hookArrayWithObjects:objs count:index];
    if (objs != stackObjects) {
        free(objs);
    }
    return result;
}

@end
