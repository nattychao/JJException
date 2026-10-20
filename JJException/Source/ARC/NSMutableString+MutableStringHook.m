//
//  NSMutableString+MutableStringHook.m
//  JJException
//
//  Created by Jezz on 2018/9/18.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import "NSMutableString+MutableStringHook.h"
#import "NSObject+SwizzleHook.h"
#import "JJExceptionProxy.h"
#import "JJExceptionMacros.h"
#import "JJExceptionRange.h"
#import "JJExceptionGuardNet.h"

JJSYNTH_DUMMY_CLASS(NSMutableString_MutableStringHook)

@implementation NSMutableString (MutableStringHook)

+ (void)jj_swizzleNSMutableString{
    //__NSCFString
    swizzleInstanceMethod(NSClassFromString(@"__NSCFString"), @selector(appendString:), @selector(hookAppendString:));
    swizzleInstanceMethod(NSClassFromString(@"__NSCFString"), @selector(insertString:atIndex:), @selector(hookInsertString:atIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSCFString"), @selector(deleteCharactersInRange:), @selector(hookDeleteCharactersInRange:));
    swizzleInstanceMethod(NSClassFromString(@"__NSCFString"), @selector(substringFromIndex:), @selector(hookSubstringFromIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSCFString"), @selector(substringToIndex:), @selector(hookSubstringToIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSCFString"), @selector(substringWithRange:), @selector(hookSubstringWithRange:));
    swizzleInstanceMethod(NSClassFromString(@"__NSCFString"), @selector(replaceCharactersInRange:withString:), @selector(hookReplaceCharactersInRange:withString:));
    swizzleInstanceMethod(NSClassFromString(@"__NSCFString"), @selector(setString:), @selector(hookSetString:));
}

- (void) hookAppendString:(NSString *)aString{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookAppendString:aString];
        return;
    }
    if (!aString){
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString appendString value:%@ parameter nil",self]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookAppendString:aString]);
}

- (void) hookInsertString:(NSString *)aString atIndex:(NSUInteger)loc{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookInsertString:aString atIndex:loc];
        return;
    }
    if (!aString || loc > self.length) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString insertString:atIndex: value:%@ paremeter string:%@ atIndex:%lu",self,aString,(unsigned long)loc]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookInsertString:aString atIndex:loc]);
}

- (void) hookDeleteCharactersInRange:(NSRange)range{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookDeleteCharactersInRange:range];
        return;
    }
    if (!JJExceptionIsValidRange(range, self.length)){
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString deleteCharactersInRange value:%@ range:%@",self,NSStringFromRange(range)]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookDeleteCharactersInRange:range]);
}

- (void) hookReplaceCharactersInRange:(NSRange)range withString:(NSString *)str{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookReplaceCharactersInRange:range withString:str];
        return;
    }
    if (!str){
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString replaceCharactersInRange:withString: value:%@ string nil range:%@",self,NSStringFromRange(range)]);
        return;
    }
    if (!JJExceptionIsValidRange(range, self.length)){
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString replaceCharactersInRange:withString: value:%@ string:%@ range:%@",self,str,NSStringFromRange(range)]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookReplaceCharactersInRange:range withString:str]);
}

- (void) hookSetString:(NSString *)aString{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookSetString:aString];
        return;
    }
    if (!aString) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString setString nil value:%@",self]);
        return;
    }
    JJ_NET_VOID(JJExceptionGuardNSStringContainer, [self hookSetString:aString]);
}

- (NSString *)hookSubstringFromIndex:(NSUInteger)from{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookSubstringFromIndex:from];
    }
    if (from > self.length) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString substringFromIndex value:%@ from:%lu",self,(unsigned long)from]);
        return nil;
    }
    return JJ_NET_SCALAR(id, JJExceptionGuardNSStringContainer, nil, [self hookSubstringFromIndex:from]);
}

- (NSString *)hookSubstringToIndex:(NSUInteger)to{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookSubstringToIndex:to];
    }
    if (to > self.length) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString substringToIndex value:%@ to:%lu",self,(unsigned long)to]);
        return self;
    }
    return JJ_NET_SCALAR(id, JJExceptionGuardNSStringContainer, nil, [self hookSubstringToIndex:to]);
}

- (NSString *)hookSubstringWithRange:(NSRange)range{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookSubstringWithRange:range];
    }
    if (!JJExceptionIsValidRange(range, self.length)) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString substringWithRange value:%@ range:%@",self,NSStringFromRange(range)]);
        return nil;
    }
    return JJ_NET_SCALAR(id, JJExceptionGuardNSStringContainer, nil, [self hookSubstringWithRange:range]);
}

@end
