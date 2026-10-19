//
//  NSString+StringHook.m
//  JJException
//
//  Created by Jezz on 2018/9/18.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import "NSString+StringHook.h"
#import "NSObject+SwizzleHook.h"
#import "JJExceptionProxy.h"
#import "JJExceptionMacros.h"
#import "JJExceptionRange.h"

JJSYNTH_DUMMY_CLASS(NSString_StringHook)

@implementation NSString (StringHook)

+ (void)jj_swizzleNSString{
    [NSString jj_swizzleClassMethod:@selector(stringWithUTF8String:) withSwizzleMethod:@selector(hookStringWithUTF8String:)];
    [NSString jj_swizzleClassMethod:@selector(stringWithCString:encoding:) withSwizzleMethod:@selector(hookStringWithCString:encoding:)];

    //NSPlaceholderString
    swizzleInstanceMethod(NSClassFromString(@"NSPlaceholderString"), @selector(initWithCString:encoding:), @selector(hookInitWithCString:encoding:));
    swizzleInstanceMethod(NSClassFromString(@"NSPlaceholderString"), @selector(initWithString:), @selector(hookInitWithString:));

    //_NSCFConstantString
    swizzleInstanceMethod(NSClassFromString(@"__NSCFConstantString"), @selector(substringFromIndex:), @selector(hookSubstringFromIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSCFConstantString"), @selector(substringToIndex:), @selector(hookSubstringToIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSCFConstantString"), @selector(substringWithRange:), @selector(hookSubstringWithRange:));
    swizzleInstanceMethod(NSClassFromString(@"__NSCFConstantString"), @selector(rangeOfString:options:range:locale:), @selector(hookRangeOfString:options:range:locale:));
    swizzleInstanceMethod(NSClassFromString(@"__NSCFConstantString"), @selector(characterAtIndex:), @selector(hookCharacterAtIndex:));

    //NSTaggedPointerString
    swizzleInstanceMethod(NSClassFromString(@"NSTaggedPointerString"), @selector(substringFromIndex:), @selector(hookSubstringFromIndex:));
    swizzleInstanceMethod(NSClassFromString(@"NSTaggedPointerString"), @selector(substringToIndex:), @selector(hookSubstringToIndex:));
    swizzleInstanceMethod(NSClassFromString(@"NSTaggedPointerString"), @selector(substringWithRange:), @selector(hookSubstringWithRange:));
    swizzleInstanceMethod(NSClassFromString(@"NSTaggedPointerString"), @selector(rangeOfString:options:range:locale:), @selector(hookRangeOfString:options:range:locale:));
    swizzleInstanceMethod(NSClassFromString(@"NSTaggedPointerString"), @selector(characterAtIndex:), @selector(hookCharacterAtIndex:));

    //__NSCFString: dynamic strings are instances of this class.
    swizzleInstanceMethod(NSClassFromString(@"__NSCFString"), @selector(characterAtIndex:), @selector(hookCharacterAtIndex:));
    swizzleInstanceMethod(NSClassFromString(@"__NSCFString"), @selector(rangeOfString:options:range:locale:), @selector(hookRangeOfString:options:range:locale:));
}

+ (NSString*) hookStringWithUTF8String:(const char *)nullTerminatedCString{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookStringWithUTF8String:nullTerminatedCString];
    }
    if (NULL != nullTerminatedCString) {
        return [self hookStringWithUTF8String:nullTerminatedCString];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,@"NSString stringWithUTF8String NULL char pointer");
    return nil;
}

+ (nullable instancetype) hookStringWithCString:(const char *)cString encoding:(NSStringEncoding)enc
{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookStringWithCString:cString encoding:enc];
    }
    if (NULL != cString){
        return [self hookStringWithCString:cString encoding:enc];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,@"NSString stringWithCString:encoding: NULL char pointer");
    return nil;
}

- (nullable instancetype) hookInitWithString:(id)cString{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookInitWithString:cString];
    }
    if (nil != cString){
        return [self hookInitWithString:cString];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,@"NSString initWithString nil parameter");
    return nil;
}

- (nullable instancetype) hookInitWithCString:(const char *)nullTerminatedCString encoding:(NSStringEncoding)encoding{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookInitWithCString:nullTerminatedCString encoding:encoding];
    }
    if (NULL != nullTerminatedCString){
        return [self hookInitWithCString:nullTerminatedCString encoding:encoding];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,@"NSString initWithCString:encoding NULL char pointer");
    return nil;
}

- (NSString *)hookSubstringFromIndex:(NSUInteger)from{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookSubstringFromIndex:from];
    }
    if (from <= self.length) {
        return [self hookSubstringFromIndex:from];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSString substringFromIndex value:%@ from:%lu",self,(unsigned long)from]);
    return nil;
}

- (NSString *)hookSubstringToIndex:(NSUInteger)to{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookSubstringToIndex:to];
    }
    if (to <= self.length) {
        return [self hookSubstringToIndex:to];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSString substringToIndex value:%@ to:%lu",self,(unsigned long)to]);
    return self;
}

- (NSString *)hookSubstringWithRange:(NSRange)range{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookSubstringWithRange:range];
    }
    if (JJExceptionIsValidRange(range, self.length)) {
        return [self hookSubstringWithRange:range];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSString substringWithRange value:%@ range:%@",self,NSStringFromRange(range)]);
    return nil;
}

- (unichar)hookCharacterAtIndex:(NSUInteger)index{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookCharacterAtIndex:index];
    }
    if (index < self.length) {
        return [self hookCharacterAtIndex:index];
    }
    handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSString characterAtIndex value:%@ index:%lu length:%lu",self,(unsigned long)index,(unsigned long)self.length]);
    return 0;
}

- (NSRange)hookRangeOfString:(NSString *)searchString options:(NSStringCompareOptions)mask range:(NSRange)range locale:(nullable NSLocale *)locale{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookRangeOfString:searchString options:mask range:range locale:locale];
    }
    if (searchString && JJExceptionIsValidRange(range, self.length)) {
        return [self hookRangeOfString:searchString options:mask range:range locale:locale];
    }
    if (!searchString) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSString rangeOfString:options:range:locale: searchString nil value:%@ range:%@",self,NSStringFromRange(range)]);
    } else {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSString rangeOfString:options:range:locale: value:%@ range:%@",self,NSStringFromRange(range)]);
    }
    return NSMakeRange(NSNotFound, 0);
}

@end
