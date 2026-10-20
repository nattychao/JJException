//
//  JJExceptionSwizzleInstaller.h
//  JJException
//
//  Safe dispatcher for the per-category swizzle entry points.
//
//  The proxy used to call them with bare `performSelector:`. That is fine when the
//  pod's "All" subspec is linked, but an app that includes only some subspecs (or a
//  build that strips a category's object file) would get an unrecognized-selector
//  crash at startup - in a crash-protection library.
//
//  All of these entry points are CLASS methods (`+jj_swizzleXxx`), so the lookup
//  has to go through the metaclass. `class_respondsToSelector(cls, sel)` only
//  inspects instance methods and would report NO for every one of them, silently
//  disabling the whole library - that exact mistake was made and caught by test.
//

#ifndef JJExceptionSwizzleInstaller_h
#define JJExceptionSwizzleInstaller_h

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/// Calls the class method `selector` on `cls` only when it is implemented.
/// Never throws: guard installation must not be able to kill startup.
static inline void JJInstallSwizzle(Class cls, SEL selector) {
    if (!cls || !selector) {
        return;
    }
    Class metaclass = object_getClass(cls);
    if (!metaclass || !class_respondsToSelector(metaclass, selector)) {
        // Category not linked in this build: skip silently. The guard for that
        // category simply stays inactive instead of killing the process.
        return;
    }
    @try {
        IMP imp = class_getMethodImplementation(metaclass, selector);
        if (imp) {
            ((void (*)(id, SEL))imp)((id)cls, selector);
        }
    } @catch (NSException *exception) {
        // Never let guard installation throw out of startup.
    }
}

#endif /* JJExceptionSwizzleInstaller_h */
