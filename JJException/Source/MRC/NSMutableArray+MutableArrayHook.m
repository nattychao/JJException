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
}

- (void) hookAddObject:(id)anObject {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookAddObject:anObject];
        return;
    }
    if (anObject) {
        [self hookAddObject:anObject];
    }else{
        handleCrashException(JJExceptionGuardArrayContainer,@"NSMutableArray addObject nil object");
    }
}

- (id) hookObjectAtIndex:(NSUInteger)index {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        return [self hookObjectAtIndex:index];
    }
    if (index < self.count) {
        return [self hookObjectAtIndex:index];
    }
    handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray objectAtIndex invalid index:%lu total:%lu",(unsigned long)index,(unsigned long)self.count]);
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
    handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray objectAtIndexedSubscript invalid index:%lu total:%lu",(unsigned long)unsignedIndex,(unsigned long)self.count]);
    return nil;
}

- (void) hookInsertObject:(id)anObject atIndex:(NSUInteger)index {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookInsertObject:anObject atIndex:index];
        return;
    }
    if (anObject && index <= self.count) {
        [self hookInsertObject:anObject atIndex:index];
    }else{
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray insertObject invalid index:%lu total:%lu insert object:%@",(unsigned long)index,(unsigned long)self.count,anObject]);
    }
}

- (void) hookRemoveObjectAtIndex:(NSUInteger)index {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookRemoveObjectAtIndex:index];
        return;
    }
    if (index < self.count) {
        [self hookRemoveObjectAtIndex:index];
    }else{
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray removeObjectAtIndex invalid index:%lu total:%lu",(unsigned long)index,(unsigned long)self.count]);
    }
}

- (void) hookReplaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookReplaceObjectAtIndex:index withObject:anObject];
        return;
    }
    if (index < self.count && anObject) {
        [self hookReplaceObjectAtIndex:index withObject:anObject];
    }else{
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray replaceObjectAtIndex invalid index:%lu total:%lu replace object:%@",(unsigned long)index,(unsigned long)self.count,anObject]);
    }
}

- (void) hookSetObject:(id)object atIndexedSubscript:(NSUInteger)index {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookSetObject:object atIndexedSubscript:index];
        return;
    }
    // Foundation raises "object cannot be nil" for a nil value and appends when
    // index == count, so both need to be checked before forwarding.
    if (object && index <= self.count) {
        [self hookSetObject:object atIndexedSubscript:index];
        return;
    }
    handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray setObject invalid object:%@ atIndexedSubscript:%lu total:%lu",object,(unsigned long)index,(unsigned long)self.count]);
}

- (void) hookRemoveObjectsInRange:(NSRange)range {
    if (!JJExceptionGuardEnabled(JJExceptionGuardArrayContainer)) {
        [self hookRemoveObjectsInRange:range];
        return;
    }
    if (JJExceptionIsValidRange(range, self.count)) {
        [self hookRemoveObjectsInRange:range];
    }else{
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray removeObjectsInRange invalid range location:%lu length:%lu total:%lu",(unsigned long)range.location,(unsigned long)range.length,(unsigned long)self.count]);
    }
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
        NSRange clamped = JJExceptionClampRange(range, self.count);
        handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray subarrayWithRange invalid range location:%lu length:%lu, clamped to location:%lu length:%lu",
                                                             (unsigned long)range.location,(unsigned long)range.length,
                                                             (unsigned long)clamped.location,(unsigned long)clamped.length]);
        return [self hookSubarrayWithRange:clamped];
    }
    handleCrashException(JJExceptionGuardArrayContainer,[NSString stringWithFormat:@"NSMutableArray subarrayWithRange invalid range location:%lu length:%lu",(unsigned long)range.location,(unsigned long)range.length]);
    return nil;
}

@end
