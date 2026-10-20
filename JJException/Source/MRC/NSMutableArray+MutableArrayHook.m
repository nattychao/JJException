//
//  NSMutableArray+MutableArrayHook.m
//  JJException
//
//  Created by Jezz on 2018/7/15.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import "NSMutableArray+MutableArrayHook.h"
#import "NSObject+SwizzleHook.h"
#import "JJExceptionProxy.h"
#import "JJExceptionMacros.h"
#import "JJExceptionRange.h"
#import "JJExceptionGuardNet.h"

JJSYNTH_DUMMY_CLASS(NSMutableArray_MutableArrayHook)

@implementation NSMutableArray (MutableArrayHook)

+ (void)jj_swizzleNSMutableArray{
    /* __NSCFArray no longer exists on modern runtimes (CFArray bridges to __NSArrayM);
       it is kept out to avoid pointless startup work. */
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(objectAtIndex:), @selector(hookObjectAtIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(subarrayWithRange:), @selector(hookSubarrayWithRange:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(objectAtIndexedSubscript:), @selector(hookObjectAtIndexedSubscript:));

    swizzleInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(addObject:), @selector(hookAddObject:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(insertObject:atIndex:), @selector(hookInsertObject:atIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(removeObjectAtIndex:), @selector(hookRemoveObjectAtIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(replaceObjectAtIndex:withObject:), @selector(hookReplaceObjectAtIndex:withObject:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(setObject:atIndexedSubscript:), @selector(hookSetObject:atIndexedSubscript:));
    swizzleInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(removeObjectsInRange:), @selector(hookRemoveObjectsInRange:));

    /* getObjects:range: is inherited from NSArray; hooking the abstract class makes
       the guard reachable for the mutable subclass too (see NSArray+ArrayHook.m). */
}

- (void) hookAddObject:(id)anObject {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookAddObject:anObject];
        return;
    }
    if (!anObject) {
        handleCrashException(JJExceptionGuardArrayContainer,@"NSMutableArray addObject nil object");
        return;
    }
    JJ_NET_VOID(JJExceptionGuardArrayContainer, [self hookAddObject:anObject]);
}

- (id) hookObjectAtIndex:(NSUInteger)index {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        return [self hookObjectAtIndex:index];
    }
    if (index >= self.count) {
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray objectAtIndex invalid index:%lu total:%lu",(unsigned long)index,(unsigned long)self.count]);
        return nil;
    }
    return JJ_NET_OBJ(JJExceptionGuardArrayContainer, nil, [self hookObjectAtIndex:index]);
}

- (id) hookObjectAtIndexedSubscript:(NSInteger)index {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        return [self hookObjectAtIndexedSubscript:index];
    }
    NSUInteger unsignedIndex = (NSUInteger)index;
    if (unsignedIndex >= self.count) {
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray objectAtIndexedSubscript invalid index:%lu total:%lu",(unsigned long)unsignedIndex,(unsigned long)self.count]);
        return nil;
    }
    return JJ_NET_OBJ(JJExceptionGuardArrayContainer, nil, [self hookObjectAtIndexedSubscript:(NSInteger)unsignedIndex]);
}

- (void) hookInsertObject:(id)anObject atIndex:(NSUInteger)index {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookInsertObject:anObject atIndex:index];
        return;
    }
    if (!anObject || index > self.count) {
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray insertObject invalid index:%lu total:%lu insert object:%@",(unsigned long)index,(unsigned long)self.count,anObject]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardArrayContainer, [self hookInsertObject:anObject atIndex:index]);
}

- (void) hookRemoveObjectAtIndex:(NSUInteger)index {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookRemoveObjectAtIndex:index];
        return;
    }
    if (index >= self.count) {
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray removeObjectAtIndex invalid index:%lu total:%lu",(unsigned long)index,(unsigned long)self.count]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardArrayContainer, [self hookRemoveObjectAtIndex:index]);
}

- (void) hookReplaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookReplaceObjectAtIndex:index withObject:anObject];
        return;
    }
    if (index >= self.count || !anObject) {
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray replaceObjectAtIndex invalid index:%lu total:%lu replace object:%@",(unsigned long)index,(unsigned long)self.count,anObject]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardArrayContainer, [self hookReplaceObjectAtIndex:index withObject:anObject]);
}

- (void) hookSetObject:(id)object atIndexedSubscript:(NSUInteger)index {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookSetObject:object atIndexedSubscript:index];
        return;
    }
    // Foundation raises "object cannot be nil" for a nil value and appends when
    // index == count, so both need to be checked before forwarding.
    if (!object || index > self.count) {
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray setObject invalid object:%@ atIndexedSubscript:%lu total:%lu",object,(unsigned long)index,(unsigned long)self.count]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardArrayContainer, [self hookSetObject:object atIndexedSubscript:index]);
}

- (void) hookRemoveObjectsInRange:(NSRange)range {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookRemoveObjectsInRange:range];
        return;
    }
    if (!JJExceptionIsValidRange(range, self.count)) {
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray removeObjectsInRange invalid range location:%lu length:%lu total:%lu",(unsigned long)range.location,(unsigned long)range.length,(unsigned long)self.count]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardArrayContainer, [self hookRemoveObjectsInRange:range]);
}

- (NSArray *)hookSubarrayWithRange:(NSRange)range
{
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        return [self hookSubarrayWithRange:range];
    }
    if (!JJExceptionIsValidRange(range, self.count)) {
        if (range.location < self.count) {
            NSRange clamped = JJExceptionClampRange(range, self.count);
            handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray subarrayWithRange invalid range location:%lu length:%lu, clamped to location:%lu length:%lu",
                                                                 (unsigned long)range.location,(unsigned long)range.length,
                                                                 (unsigned long)clamped.location,(unsigned long)clamped.length]);
            return JJ_NET_OBJ(JJExceptionGuardArrayContainer, nil, [self hookSubarrayWithRange:clamped]);
        }
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray subarrayWithRange invalid range location:%lu length:%lu",(unsigned long)range.location,(unsigned long)range.length]);
        return nil;
    }
    return JJ_NET_OBJ(JJExceptionGuardArrayContainer, nil, [self hookSubarrayWithRange:range]);
}

@end
