//
//  NSAttributedString+AttributedStringHook.m
//  JJException
//
//  Created by Jezz on 2018/9/20.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import "NSAttributedString+AttributedStringHook.h"
#import "NSObject+SwizzleHook.h"
#import <objc/runtime.h>
#import "JJExceptionProxy.h"
#import "JJExceptionMacros.h"
#import "JJExceptionRange.h"

JJSYNTH_DUMMY_CLASS(NSAttributedString_AttributedStringHook)

@implementation NSAttributedString (AttributedStringHook)

+ (void)jj_swizzleNSAttributedString{
    // Resolve the concrete class once instead of leaking a probe instance.
    NSAttributedString* instanceObject = [[NSAttributedString alloc] initWithString:@""];
    Class cls = object_getClass(instanceObject);
    if (!cls) {
        return;
    }

    swizzleInstanceMethod(cls, @selector(initWithString:), @selector(hookInitWithString:));
    swizzleInstanceMethod(cls, @selector(attributedSubstringFromRange:), @selector(hookAttributedSubstringFromRange:));
    swizzleInstanceMethod(cls, @selector(attribute:atIndex:effectiveRange:), @selector(hookAttribute:atIndex:effectiveRange:));
    swizzleInstanceMethod(cls, @selector(enumerateAttribute:inRange:options:usingBlock:), @selector(hookEnumerateAttribute:inRange:options:usingBlock:));
    swizzleInstanceMethod(cls, @selector(enumerateAttributesInRange:options:usingBlock:), @selector(hookEnumerateAttributesInRange:options:usingBlock:));
}

- (id)hookInitWithString:(NSString*)str{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookInitWithString:str];
    }
    if (str){
        return [self hookInitWithString:str];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,@"NSAttributedString initWithString parameter nil");
    return nil;
}

- (id)hookAttribute:(NSAttributedStringKey)attrName atIndex:(NSUInteger)location effectiveRange:(nullable NSRangePointer)range{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookAttribute:attrName atIndex:location effectiveRange:range];
    }
    if (location < self.length){
        return [self hookAttribute:attrName atIndex:location effectiveRange:range];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSAttributedString attribute:atIndex:effectiveRange: attrName:%@ location:%lu length:%lu",attrName,(unsigned long)location,(unsigned long)self.length]);
    return nil;
}

- (NSAttributedString *)hookAttributedSubstringFromRange:(NSRange)range{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookAttributedSubstringFromRange:range];
    }
    if (JJExceptionIsValidRange(range, self.length)) {
        return [self hookAttributedSubstringFromRange:range];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSAttributedString attributedSubstringFromRange range:%@ length:%lu",NSStringFromRange(range),(unsigned long)self.length]);
    return nil;
}

- (void)hookEnumerateAttribute:(NSString *)attrName inRange:(NSRange)range options:(NSAttributedStringEnumerationOptions)opts usingBlock:(void (^)(id _Nullable, NSRange, BOOL * _Nonnull))block{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookEnumerateAttribute:attrName inRange:range options:opts usingBlock:block];
        return;
    }
    // An empty range at `length` is legal for enumeration; NSNotFound is not.
    if (JJExceptionIsValidRange(range, self.length)) {
        [self hookEnumerateAttribute:attrName inRange:range options:opts usingBlock:block];
    }else{
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSAttributedString enumerateAttribute attrName:%@ range:%@ length:%lu",attrName,NSStringFromRange(range),(unsigned long)self.length]);
    }
}

- (void)hookEnumerateAttributesInRange:(NSRange)range options:(NSAttributedStringEnumerationOptions)opts usingBlock:(void (^)(NSDictionary<NSString*,id> * _Nonnull, NSRange, BOOL * _Nonnull))block{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookEnumerateAttributesInRange:range options:opts usingBlock:block];
        return;
    }
    // {NSNotFound, 0} means "the whole string" and is forwarded untouched.
    if (range.location == NSNotFound && range.length == 0) {
        [self hookEnumerateAttributesInRange:range options:opts usingBlock:block];
        return;
    }
    if (JJExceptionIsValidRange(range, self.length)) {
        [self hookEnumerateAttributesInRange:range options:opts usingBlock:block];
    } else {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSAttributedString enumerateAttributesInRange range:%@ length:%lu",NSStringFromRange(range),(unsigned long)self.length]);
    }
}

@end
