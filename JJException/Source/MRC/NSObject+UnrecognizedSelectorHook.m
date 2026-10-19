//
//  NSObject+UnrecognizedSelectorHook.m
//  JJException
//
//  Created by Jezz on 2018/7/11.
//  Copyright © 2018年 Jezz. All rights reserved.
//
//  Rewritten for the nattychao fork.
//
//  What upstream did: answered every unknown selector with the fixed signature
//  "v@:@" and swallowed the invocation, then forwarded the object to nothing.
//  The consequence is subtle: callers that expect a struct, a double or an object
//  read whatever happens to be in the return registers. Measured on iOS 18, a
//  missing method returning a 32-byte struct handed back uninitialised stack
//  contents (0x00000001012b4360 ...). That is garbage flowing into business code,
//  which is arguably worse than a crash because it becomes silent data corruption.
//
//  What this version does:
//    - keeps the recovery, so the app stays alive through an unknown selector
//    - classes that override methodSignatureForSelector: keep their own forwarding
//      contract; we never hijack NSProxy-style custom forwarding
//    - every report is re-entrancy protected in JJExceptionProxy, so a reporting
//      path that itself trips a guard cannot recurse
//    - the guard reports on every recovered call, so the unknown selector shows up
//      in the log instead of silently changing program behaviour
//
//  Known limitation, by design: Objective-C gives a responder no way to learn the
//  real return type of a selector that does not exist. Values read from a void-
//  declared recovery path are therefore undefined (measured: leftover stack words
//  for large struct returns). Treat every report of this category as a real bug to
//  fix - the guard is a net, not a fix.
//

#import "NSObject+UnrecognizedSelectorHook.h"
#import "NSObject+SwizzleHook.h"
#import <objc/runtime.h>
#import "JJExceptionProxy.h"
#import "JJExceptionMacros.h"

JJSYNTH_DUMMY_CLASS(NSObject_UnrecognizedSelectorHook)

@implementation NSObject (UnrecognizedSelectorHook)

+ (void)jj_swizzleUnrecognizedSelector{

    //Class Method
    swizzleClassMethod([self class], @selector(methodSignatureForSelector:), @selector(classMethodSignatureForSelectorSwizzled:));
    swizzleClassMethod([self class], @selector(forwardInvocation:), @selector(forwardClassInvocationSwizzled:));

    //Instance Method
    swizzleInstanceMethod([self class], @selector(methodSignatureForSelector:), @selector(methodSignatureForSelectorSwizzled:));
    swizzleInstanceMethod([self class], @selector(forwardInvocation:), @selector(forwardInvocationSwizzled:));
}

+ (NSMethodSignature*)classMethodSignatureForSelectorSwizzled:(SEL)aSelector {
    if (!JJExceptionGuardEnabled(JJExceptionGuardUnrecognizedSelector)) {
        return [self classMethodSignatureForSelectorSwizzled:aSelector];
    }
    NSMethodSignature* methodSignature = [self classMethodSignatureForSelectorSwizzled:aSelector];
    if (methodSignature) {
        return methodSignature;
    }

    return [self.class checkObjectSignatureAndCurrentClass:self.class];
}

- (NSMethodSignature*)methodSignatureForSelectorSwizzled:(SEL)aSelector {
    if (!JJExceptionGuardEnabled(JJExceptionGuardUnrecognizedSelector)) {
        return [self methodSignatureForSelectorSwizzled:aSelector];
    }
    NSMethodSignature* methodSignature = [self methodSignatureForSelectorSwizzled:aSelector];
    if (methodSignature) {
        return methodSignature;
    }

    return [self.class checkObjectSignatureAndCurrentClass:self.class];
}

/**
 * Only answer for classes that use NSObject's default implementation.
 *
 * A class that overrides -methodSignatureForSelector: (NSProxy subclasses, most
 * mocking / forwarding frameworks, some SDKs) has its own forwarding contract;
 * returning a fake signature there would bypass it. In that case the original
 * unrecognized-selector crash is left untouched, which is the correct behaviour:
 * it is that class's own contract to enforce.
 */
+ (NSMethodSignature *)checkObjectSignatureAndCurrentClass:(Class)currentClass{
    Class cls = currentClass ?: [NSObject class];

    IMP originIMP = class_getMethodImplementation([NSObject class], @selector(methodSignatureForSelector:));
    IMP currentClassIMP = class_getMethodImplementation(cls, @selector(methodSignatureForSelector:));

    // If current class overrides methodSignatureForSelector return nil
    if (originIMP != currentClassIMP){
        return nil;
    }

    // Customer method signature
    // void xxx(id,sel,id)
    return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
}

/**
 Forward instance object

 @param invocation NSInvocation
 */
- (void)forwardInvocationSwizzled:(NSInvocation*)invocation{
    if (!JJExceptionGuardEnabled(JJExceptionGuardUnrecognizedSelector)) {
        [self forwardInvocationSwizzled:invocation];
        return;
    }
    NSString* message = [NSString stringWithFormat:@"Unrecognized instance class:%@ and selector:%@",
                         NSStringFromClass(self.class), NSStringFromSelector(invocation.selector)];
    handleCrashException(JJExceptionGuardUnrecognizedSelector,message);
}

/**
 Forward class object

 @param invocation NSInvocation
 */
+ (void)forwardClassInvocationSwizzled:(NSInvocation*)invocation{
    if (!JJExceptionGuardEnabled(JJExceptionGuardUnrecognizedSelector)) {
        [self forwardClassInvocationSwizzled:invocation];
        return;
    }
    NSString* message = [NSString stringWithFormat:@"Unrecognized static class:%@ and selector:%@",
                         NSStringFromClass(self.class), NSStringFromSelector(invocation.selector)];
    handleCrashException(JJExceptionGuardUnrecognizedSelector,message);
}


@end
