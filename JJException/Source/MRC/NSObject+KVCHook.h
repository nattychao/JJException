//
//  NSObject+KVCHook.h
//  JJException
//
//  KVC guard. Not present in upstream JJException at all; the crash points below
//  were enumerated from chenfanfang/AvoidCrash and verified on iOS 18.6 / 27.x.
//

#import <Foundation/Foundation.h>

@interface NSObject (KVCHook)

/// Swizzles the NSObject-level KVC entry points.
+ (void)jj_swizzleKVC;

/// Swizzles the KVC entry points that Foundation overrides on a class other than
/// NSObject. Must use its own hook selectors: NSMutableDictionary and NSArray
/// override -setValue:forKey:, and reusing the NSObject hook selector would let the
/// swizzle capture NSObject's original IMP instead of the hook.
+ (void)jj_swizzleKVCContainerOverrides;

@end
