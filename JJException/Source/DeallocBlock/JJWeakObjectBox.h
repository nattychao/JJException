//
//  JJWeakObjectBox.h
//  JJException
//
//  A zeroing weak container. The KVO bookkeeping needs weak references, but
//  NSObject+KVOCrash.m is compiled without ARC (the pod's MRC subspec) and
//  clang refuses `__weak` in MRC translation units. This tiny ARC-compiled
//  class gives that code a safe way to hold a non-retaining reference.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JJWeakObjectBox : NSObject

- (instancetype)initWithObject:(id)object;

/// Weakly loaded object, or nil once the referent is deallocated.
@property (nonatomic, readonly, nullable) id object;

@end

NS_ASSUME_NONNULL_END
