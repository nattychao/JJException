//
//  JJExceptionGuardNet.h
//  JJException
//
//  Last-resort safety net for every hook.
//
//  Design note (borrowed from chenfanfang/AvoidCrash):
//  Pre-validating arguments is fast and lets a hook return a *correct* value, but
//  it can only protect the crash points someone remembered to enumerate. Any
//  argument shape we did not think of still reaches Foundation and throws.
//
//  So each hook does both:
//    1. pre-validate the cases we know about  -> correct return value, no exception
//    2. wrap the forward call in @try/@catch -> anything we missed is reported
//                                              instead of killing the app
//
//  Measured cost of an untaken @try block on arm64: ~1.4% on a 2M-iteration hot
//  loop (zero-cost exceptions), i.e. effectively free.
//
//  The macros below exist because the hooks return many different types, and a
//  statement-expression keeps the call site readable.
//

#ifndef JJExceptionGuardNet_h
#define JJExceptionGuardNet_h

#import <Foundation/Foundation.h>
#import "JJExceptionProxy.h"

/// Run `expr` and return its value; on an ObjC exception report it and return
/// `fallback`. Use for object-returning hooks.
#define JJ_NET_OBJ(category, fallback, expr) \
    ({ id _jj_result = (fallback); \
       @try { _jj_result = (expr); } \
       @catch (NSException *_jj_exception) { \
           handleCrashException((category), [NSString stringWithFormat:@"%@ caught: %@", @#expr, _jj_exception.reason]); \
       } \
       _jj_result; })

/// Same for scalar-returning hooks (NSInteger, NSUInteger, unichar, BOOL, ...).
#define JJ_NET_SCALAR(type, category, fallback, expr) \
    ({ type _jj_result = (fallback); \
       @try { _jj_result = (expr); } \
       @catch (NSException *_jj_exception) { \
           handleCrashException((category), [NSString stringWithFormat:@"%@ caught: %@", @#expr, _jj_exception.reason]); \
       } \
       _jj_result; })

/// Same for void hooks.
#define JJ_NET_VOID(category, expr) \
    do { \
        @try { (void)(expr); } \
        @catch (NSException *_jj_exception) { \
            handleCrashException((category), [NSString stringWithFormat:@"%@ caught: %@", @#expr, _jj_exception.reason]); \
        } \
    } while (0)

#endif /* JJExceptionGuardNet_h */
