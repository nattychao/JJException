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
#import "JJExceptionGuardNet.h"

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
    if (!str){
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSMutableAttributedString initWithString parameter nil");
        return nil;
    }
    return JJ_NET_SCALAR(id, JJExceptionGuardNSStringContainer, nil, [self hookInitWithString:str]);
}

- (id)hookInitWithString:(NSString*)str attributes:(nullable NSDictionary*)attributes{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookInitWithString:str attributes:attributes];
    }
    if (!str){
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString initWithString:attributes: str:%@ attributes:%@",str,attributes]);
        return nil;
    }
    return JJ_NET_SCALAR(id, JJExceptionGuardNSStringContainer, nil,
                         [self hookInitWithString:str attributes:attributes]);
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
        JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookAddAttribute:name value:value range:range]);
        return;
    }
    if (!value) {
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSMutableAttributedString addAttribute:value:range: value nil");
        return;
    }
    if (!JJExceptionIsValidRange(range, self.length)) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString addAttribute:value:range: name:%@ value:%@ range:%@ length:%lu",name,value,NSStringFromRange(range),(unsigned long)self.length]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookAddAttribute:name value:value range:range]);
}

- (void)hookAddAttributes:(NSDictionary<NSString *,id> *)attrs range:(NSRange)range{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookAddAttributes:attrs range:range];
        return;
    }
    if (!range.length) {
        JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookAddAttributes:attrs range:range]);
        return;
    }
    if (!attrs) {
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSMutableAttributedString addAttributes:range: value nil");
        return;
    }
    if (!JJExceptionIsValidRange(range, self.length)) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString addAttributes:range: attrs:%@ range:%@ length:%lu",attrs,NSStringFromRange(range),(unsigned long)self.length]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookAddAttributes:attrs range:range]);
}

- (void)hookSetAttributes:(NSDictionary<NSString *,id> *)attrs range:(NSRange)range {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookSetAttributes:attrs range:range];
        return;
    }
    if (!range.length) {
        JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookSetAttributes:attrs range:range]);
        return;
    }
    if (!JJExceptionIsValidRange(range, self.length)) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString setAttributes:range: attrs:%@ range:%@ length:%lu",attrs,NSStringFromRange(range),(unsigned long)self.length]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookSetAttributes:attrs range:range]);
}

- (void)hookRemoveAttribute:(id)name range:(NSRange)range {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookRemoveAttribute:name range:range];
        return;
    }
    if (!range.length) {
        JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookRemoveAttribute:name range:range]);
        return;
    }
    if (!name) {
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSMutableAttributedString removeAttribute:range: name nil");
        return;
    }
    if (!JJExceptionIsValidRange(range, self.length)) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString removeAttribute:range: name:%@ range:%@ length:%lu",name,NSStringFromRange(range),(unsigned long)self.length]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookRemoveAttribute:name range:range]);
}

- (void)hookDeleteCharactersInRange:(NSRange)range {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookDeleteCharactersInRange:range];
        return;
    }
    if (!JJExceptionIsValidRange(range, self.length)) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString deleteCharactersInRange: range:%@ length:%lu",NSStringFromRange(range),(unsigned long)self.length]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookDeleteCharactersInRange:range]);
}

- (void)hookReplaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookReplaceCharactersInRange:range withString:str];
        return;
    }
    if (!str) {
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSMutableAttributedString replaceCharactersInRange:withString: string nil");
        return;
    }
    if (!JJExceptionIsValidRange(range, self.length)) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString replaceCharactersInRange:withString: string:%@ range:%@ length:%lu",str,NSStringFromRange(range),(unsigned long)self.length]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookReplaceCharactersInRange:range withString:str]);
}

- (void)hookReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)str {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookReplaceCharactersInRange:range withAttributedString:str];
        return;
    }
    if (!str) {
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSMutableAttributedString replaceCharactersInRange:withAttributedString: attributedString nil");
        return;
    }
    if (!JJExceptionIsValidRange(range, self.length)) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableAttributedString replaceCharactersInRange:withAttributedString: string:%@ range:%@ length:%lu",str,NSStringFromRange(range),(unsigned long)self.length]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookReplaceCharactersInRange:range withAttributedString:str]);
}

@end
