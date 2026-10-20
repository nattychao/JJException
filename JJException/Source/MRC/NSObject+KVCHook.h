//
//  NSObject+KVCHook.h
//  JJException
//
//  KVC guard. Not present in upstream JJException at all; the crash points below
//  were enumerated from chenfanfang/AvoidCrash and verified on iOS 18.6 / 27.x.
//

#import <Foundation/Foundation.h>

@interface NSObject (KVCHook)

+ (void)jj_swizzleKVC;

@end
