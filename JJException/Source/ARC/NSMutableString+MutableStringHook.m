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
    if (aString){
        [self hookAppendString:aString];
    }else{
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString appendString value:%@ parameter nil",self]);
    }
}

- (void) hookInsertString:(NSString *)aString atIndex:(NSUInteger)loc{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookInsertString:aString atIndex:loc];
        return;
    }
    if (aString && loc <= self.length) {
        [self hookInsertString:aString atIndex:loc];
    }else{
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString insertString:atIndex: value:%@ paremeter string:%@ atIndex:%lu",self,aString,(unsigned long)loc]);
    }
}

- (void) hookDeleteCharactersInRange:(NSRange)range{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookDeleteCharactersInRange:range];
        return;
    }
    if (JJExceptionIsValidRange(range, self.length)){
        [self hookDeleteCharactersInRange:range];
    }else{
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString deleteCharactersInRange value:%@ range:%@",self,NSStringFromRange(range)]);
    }
}

- (void) hookReplaceCharactersInRange:(NSRange)range withString:(NSString *)str{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookReplaceCharactersInRange:range withString:str];
        return;
    }
    if (str && JJExceptionIsValidRange(range, self.length)) {
        [self hookReplaceCharactersInRange:range withString:str];
    }else if (!str){
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString replaceCharactersInRange:withString: value:%@ string nil range:%@",self,NSStringFromRange(range)]);
    }else{
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString replaceCharactersInRange:withString: value:%@ string:%@ range:%@",self,str,NSStringFromRange(range)]);
    }
}

- (void) hookSetString:(NSString *)aString{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        [self hookSetString:aString];
        return;
    }
    if (aString) {
        [self hookSetString:aString];
    }else{
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString setString nil value:%@",self]);
    }
}

- (NSString *)hookSubstringFromIndex:(NSUInteger)from{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookSubstringFromIndex:from];
    }
    if (from <= self.length) {
        return [self hookSubstringFromIndex:from];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString substringFromIndex value:%@ from:%lu",self,(unsigned long)from]);
    return nil;
}

- (NSString *)hookSubstringToIndex:(NSUInteger)to{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookSubstringToIndex:to];
    }
    if (to <= self.length) {
        return [self hookSubstringToIndex:to];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString substringToIndex value:%@ to:%lu",self,(unsigned long)to]);
    return self;
}

- (NSString *)hookSubstringWithRange:(NSRange)range{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookSubstringWithRange:range];
    }
    if (JJExceptionIsValidRange(range, self.length)) {
        return [self hookSubstringWithRange:range];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSMutableString substringWithRange value:%@ range:%@",self,NSStringFromRange(range)]);
    return nil;
}

@end
