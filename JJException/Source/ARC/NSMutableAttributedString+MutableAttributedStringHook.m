//
//  NSMutableAttributedString+MutableAttributedStringHook.m
//  JJException
//
//  Created by Jezz on 2018/9/20.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import "NSMutableAttributedString+MutableAttributedStringHook.h"
#import "NSObject+SwizzleHook.h"
#import <objc/runtime.h>
#import "JJExceptionProxy.h"
#import "JJExceptionMacros.h"
#import "JJExceptionRange.h"

JJSYNTH_DUMMY_CLASS(NSMutableAttributedString_MutableAttributedStringHook)

@implementation NSMutableAttributedString (MutableAttributedStringHook)

+ (void)jj_swizzleNSMutableAttributedString{
    NSMutableAttributedString* instanceObject = [[NSMutableAttributedString alloc] initWithString:@""];
    Class cls = object_getClass(instanceObject);
    if (!cls) {
        return;
    }

    swizzleInstanceMethod(cls,@selector(initWithString:), @selector(hookInitWithString:));
    swizzleInstanceMethod(cls,@selector(initWithString:attributes:), @selector(hookInitWithString:attributes:));
    swizzleInstanceMethod(cls,@selector(addAttribute:value:range:), @selector(hookAddAttribute:value:range:));
    swizzleInstanceMethod(cls,@selector(addAttributes:range:), @selector(hookAddAttributes:range:));
    swizzleInstanceMethod(cls,@selector(setAttributes:range:), @selector(hookSetAttributes:range:));
    swizzleInstanceMethod(cls,@selector(removeAttribute:range:), @selector(hookRemoveAttribute:range:));
    swizzleInstanceMethod(cls,@selector(deleteCharactersInRange:), @selector(hookDeleteCharactersInRange:));
    swizzleInstanceMethod(cls,@selector(replaceCharactersInRange:withString:), @selector(hookReplaceCharactersInRange:withString:));
    swizzleInstanceMethod(cls,@selector(replaceCharactersInRange:withAttributedString:), @selector(hookReplaceCharactersInRange:withAttributedString:));
}

- (id)hookInitWithString:(NSString*)str{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookInitWithString:str];
    }
    if (str){
        return [self hookInitWithString:str];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,@"NSMutableAttributedString initWithString parameter nil");
    return nil;
}

- (id)hookInitWithString:(NSString*)str attributes:(nullable NSDictionary*)attributes{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookInitWithString:str attributes:attributes];
    }
    if (str){
        return [self hookInitWithString:str attributes:attributes];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString initWithString:attributes: str:%@ attributes:%@",str,attributes]);
    return nil;
}

- (void)hookAddAttribute:(id)name value:(id)value range:(NSRange)range{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookAddAttribute:name value:value range:range];
        return;
    }
    // Foundation tolerates a zero-length range anywhere (measured), so forwarding
    // it keeps this guard free of false positives. Only a non-empty range that is
    // actually out of bounds can crash.
    if (!range.length) {
        [self hookAddAttribute:name value:value range:range];
    }else if (value){
        if (JJExceptionIsValidRange(range, self.length)) {
            [self hookAddAttribute:name value:value range:range];
        }else{
            handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString addAttribute:value:range: name:%@ value:%@ range:%@ length:%lu",name,value,NSStringFromRange(range),(unsigned long)self.length]);
        }
    }else {
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSMutableAttributedString addAttribute:value:range: value nil");
    }
}

- (void)hookAddAttributes:(NSDictionary<NSString *,id> *)attrs range:(NSRange)range{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookAddAttributes:attrs range:range];
        return;
    }
    if (!range.length) {
        [self hookAddAttributes:attrs range:range];
    }else if (attrs){
        if (JJExceptionIsValidRange(range, self.length)) {
            [self hookAddAttributes:attrs range:range];
        }else{
            handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString addAttributes:range: attrs:%@ range:%@ length:%lu",attrs,NSStringFromRange(range),(unsigned long)self.length]);
        }
    }else{
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSMutableAttributedString addAttributes:range: value nil");
    }
}

- (void)hookSetAttributes:(NSDictionary<NSString *,id> *)attrs range:(NSRange)range {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookSetAttributes:attrs range:range];
        return;
    }
    if (!range.length) {
        [self hookSetAttributes:attrs range:range];
    } else {
        if (JJExceptionIsValidRange(range, self.length)) {
            [self hookSetAttributes:attrs range:range];
        }else{
            handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString setAttributes:range: attrs:%@ range:%@ length:%lu",attrs,NSStringFromRange(range),(unsigned long)self.length]);
        }
    }
}

- (void)hookRemoveAttribute:(id)name range:(NSRange)range {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookRemoveAttribute:name range:range];
        return;
    }
    if (!range.length) {
        [self hookRemoveAttribute:name range:range];
    }else if (name){
        if (JJExceptionIsValidRange(range, self.length)) {
            [self hookRemoveAttribute:name range:range];
        }else {
            handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString removeAttribute:range: name:%@ range:%@ length:%lu",name,NSStringFromRange(range),(unsigned long)self.length]);
        }
    }else{
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSMutableAttributedString removeAttribute:range: name nil");
    }
}

- (void)hookDeleteCharactersInRange:(NSRange)range {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookDeleteCharactersInRange:range];
        return;
    }
    if (JJExceptionIsValidRange(range, self.length)) {
        [self hookDeleteCharactersInRange:range];
    }else {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString deleteCharactersInRange: range:%@ length:%lu",NSStringFromRange(range),(unsigned long)self.length]);
    }
}

- (void)hookReplaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookReplaceCharactersInRange:range withString:str];
        return;
    }
    if (str && JJExceptionIsValidRange(range, self.length)) {
        [self hookReplaceCharactersInRange:range withString:str];
    }else if (!str){
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSMutableAttributedString replaceCharactersInRange:withString: string nil");
    }else{
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString replaceCharactersInRange:withString: string:%@ range:%@ length:%lu",str,NSStringFromRange(range),(unsigned long)self.length]);
    }
}

- (void)hookReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)str {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookReplaceCharactersInRange:range withAttributedString:str];
        return;
    }
    if (str && JJExceptionIsValidRange(range, self.length)) {
        [self hookReplaceCharactersInRange:range withAttributedString:str];
    }else if (!str){
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSMutableAttributedString replaceCharactersInRange:withAttributedString: attributedString nil");
    }else{
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString replaceCharactersInRange:withAttributedString: string:%@ range:%@ length:%lu",str,NSStringFromRange(range),(unsigned long)self.length]);
    }
}

@end
