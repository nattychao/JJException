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
#import "JJExceptionGuardNet.h"

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

    // Implemented by NSString itself, so hooking the abstract class covers all the
    // concrete subclasses above (verified: owner == NSString for every backing
    // class). These throw NSRangeException / NSInvalidArgumentException on bad
    // input (measured) and were not covered.
    swizzleInstanceMethod(NSClassFromString(@"NSString"), @selector(stringByReplacingCharactersInRange:withString:), @selector(hookStringByReplacingCharactersInRange:withString:));
    swizzleInstanceMethod(NSClassFromString(@"NSString"), @selector(stringByReplacingOccurrencesOfString:withString:), @selector(hookStringByReplacingOccurrencesOfString:withString:));
    swizzleInstanceMethod(NSClassFromString(@"NSString"), @selector(stringByReplacingOccurrencesOfString:withString:options:range:), @selector(hookStringByReplacingOccurrencesOfString:withString:options:range:));
    swizzleInstanceMethod(NSClassFromString(@"NSString"), @selector(stringByAppendingString:), @selector(hookStringByAppendingString:));
}

+ (NSString*) hookStringWithUTF8String:(const char *)nullTerminatedCString{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookStringWithUTF8String:nullTerminatedCString];
    }
    if (!nullTerminatedCString) {
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSString stringWithUTF8String NULL char pointer");
        return nil;
    }
    return JJ_NET_OBJ(JJExceptionGuardNSStringContainer, nil, [self hookStringWithUTF8String:nullTerminatedCString]);
}

+ (nullable instancetype) hookStringWithCString:(const char *)cString encoding:(NSStringEncoding)enc
{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookStringWithCString:cString encoding:enc];
    }
    if (!cString){
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSString stringWithCString:encoding: NULL char pointer");
        return nil;
    }
    return JJ_NET_OBJ(JJExceptionGuardNSStringContainer, nil, [self hookStringWithCString:cString encoding:enc]);
}

- (nullable instancetype) hookInitWithString:(id)cString{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookInitWithString:cString];
    }
    if (!cString){
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSString initWithString nil parameter");
        return nil;
    }
    return JJ_NET_OBJ(JJExceptionGuardNSStringContainer, nil, [self hookInitWithString:cString]);
}

- (nullable instancetype) hookInitWithCString:(const char *)nullTerminatedCString encoding:(NSStringEncoding)encoding{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookInitWithCString:nullTerminatedCString encoding:encoding];
    }
    if (!nullTerminatedCString){
        handleCrashException(JJExceptionGuardNSStringContainer,@"NSString initWithCString:encoding NULL char pointer");
        return nil;
    }
    return JJ_NET_OBJ(JJExceptionGuardNSStringContainer, nil, [self hookInitWithCString:nullTerminatedCString encoding:encoding]);
}

- (NSString *)hookSubstringFromIndex:(NSUInteger)from{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookSubstringFromIndex:from];
    }
    if (from > self.length) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSString substringFromIndex value:%@ from:%lu",self,(unsigned long)from]);
        return nil;
    }
    return JJ_NET_OBJ(JJExceptionGuardNSStringContainer, nil, [self hookSubstringFromIndex:from]);
}

- (NSString *)hookSubstringToIndex:(NSUInteger)to{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookSubstringToIndex:to];
    }
    if (to > self.length) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSString substringToIndex value:%@ to:%lu",self,(unsigned long)to]);
        return self;
    }
    return JJ_NET_OBJ(JJExceptionGuardNSStringContainer, nil, [self hookSubstringToIndex:to]);
}

- (NSString *)hookSubstringWithRange:(NSRange)range{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookSubstringWithRange:range];
    }
    if (!JJExceptionIsValidRange(range, self.length)) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSString substringWithRange value:%@ range:%@",self,NSStringFromRange(range)]);
        return nil;
    }
    return JJ_NET_OBJ(JJExceptionGuardNSStringContainer, nil, [self hookSubstringWithRange:range]);
}

- (unichar)hookCharacterAtIndex:(NSUInteger)index{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookCharacterAtIndex:index];
    }
    if (index >= self.length) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSString characterAtIndex value:%@ index:%lu length:%lu",self,(unsigned long)index,(unsigned long)self.length]);
        return 0;
    }
    return JJ_NET_SCALAR(unichar, JJExceptionGuardNSStringContainer, 0, [self hookCharacterAtIndex:index]);
}

- (NSRange)hookRangeOfString:(NSString *)searchString options:(NSStringCompareOptions)mask range:(NSRange)range locale:(nullable NSLocale *)locale{
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookRangeOfString:searchString options:mask range:range locale:locale];
    }
    if (!searchString) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSString rangeOfString:options:range:locale: searchString nil value:%@ range:%@",self,NSStringFromRange(range)]);
        return NSMakeRange(NSNotFound, 0);
    }
    if (!JJExceptionIsValidRange(range, self.length)) {
        handleCrashException(JJExceptionGuardNSStringContainer,[NSString stringWithFormat:@"NSString rangeOfString:options:range:locale: value:%@ range:%@",self,NSStringFromRange(range)]);
        return NSMakeRange(NSNotFound, 0);
    }
    return JJ_NET_SCALAR(NSRange, JJExceptionGuardNSStringContainer, NSMakeRange(NSNotFound, 0),
                         [self hookRangeOfString:searchString options:mask range:range locale:locale]);
}

#pragma mark - Replacing / appending

- (NSString *)hookStringByReplacingCharactersInRange:(NSRange)range withString:(NSString *)replacement {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookStringByReplacingCharactersInRange:range withString:replacement];
    }
    if (!replacement) {
        handleCrashException(JJExceptionGuardNSStringContainer,
                             [NSString stringWithFormat:@"NSString stringByReplacingCharactersInRange:withString: nil replacement value:%@ range:%@", self, NSStringFromRange(range)]);
        return self;
    }
    if (!JJExceptionIsValidRange(range, self.length)) {
        handleCrashException(JJExceptionGuardNSStringContainer,
                             [NSString stringWithFormat:@"NSString stringByReplacingCharactersInRange:withString: invalid range:%@ length:%lu", NSStringFromRange(range), (unsigned long)self.length]);
        return self;
    }
    return JJ_NET_OBJ(JJExceptionGuardNSStringContainer, self, [self hookStringByReplacingCharactersInRange:range withString:replacement]);
}

- (NSString *)hookStringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookStringByReplacingOccurrencesOfString:target withString:replacement];
    }
    if (!target) {
        handleCrashException(JJExceptionGuardNSStringContainer, @"NSString stringByReplacingOccurrencesOfString:withString: nil target");
        return self;
    }
    return JJ_NET_OBJ(JJExceptionGuardNSStringContainer, self, [self hookStringByReplacingOccurrencesOfString:target withString:replacement]);
}

- (NSString *)hookStringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(NSStringCompareOptions)options range:(NSRange)searchRange {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookStringByReplacingOccurrencesOfString:target withString:replacement options:options range:searchRange];
    }
    if (!target) {
        handleCrashException(JJExceptionGuardNSStringContainer, @"NSString stringByReplacingOccurrencesOfString:withString:options:range: nil target");
        return self;
    }
    if (!JJExceptionIsValidRange(searchRange, self.length)) {
        handleCrashException(JJExceptionGuardNSStringContainer,
                             [NSString stringWithFormat:@"NSString stringByReplacingOccurrencesOfString:withString:options:range: invalid range:%@ length:%lu", NSStringFromRange(searchRange), (unsigned long)self.length]);
        return self;
    }
    return JJ_NET_OBJ(JJExceptionGuardNSStringContainer, self,
                      [self hookStringByReplacingOccurrencesOfString:target withString:replacement options:options range:searchRange]);
}

- (NSString *)hookStringByAppendingString:(NSString *)aString {
    if (!JJExceptionGuardEnabled(JJExceptionGuardNSStringContainer)) {
        return [self hookStringByAppendingString:aString];
    }
    if (!aString) {
        handleCrashException(JJExceptionGuardNSStringContainer,
                             [NSString stringWithFormat:@"NSString stringByAppendingString: nil argument value:%@", self]);
        return self;
    }
    return JJ_NET_OBJ(JJExceptionGuardNSStringContainer, self, [self hookStringByAppendingString:aString]);
}

@end
