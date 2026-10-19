//
//  JJExceptionProxy.h
//  JJException
//
//  Created by Jezz on 2018/7/22.
//  Copyright © 2018年 Jezz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JJException.h"

NS_ASSUME_NONNULL_BEGIN

/**
 C style invoke handle crash message

 @param exceptionMessage crash message
 */
__attribute__((overloadable)) void handleCrashException(NSString* exceptionMessage);

/**
 C style invoke handle crash message,and extra crash info

 @param exceptionMessage crash message
 @param extraInfo extra crash message
 */
__attribute__((overloadable)) void handleCrashException(NSString* exceptionMessage,NSDictionary* extraInfo);

/**
 C style invoke handle crash message,and extra crash info
 
 @param exceptionCategory crash type
 @param exceptionMessage crash message
 @param extraInfo extra info
 */
__attribute__((overloadable)) void handleCrashException(JJExceptionGuardCategory exceptionCategory, NSString* exceptionMessage,NSDictionary* extraInfo);

/**
 C style invoke handle crash type,and exception message
 
 @param exceptionCategory JJExceptionGuardCategory
 @param exceptionMessage crash message
 */
__attribute__((overloadable)) void handleCrashException(JJExceptionGuardCategory exceptionCategory, NSString* exceptionMessage);

/**
 Exception Proxy
 */
@interface JJExceptionProxy : NSObject<JJExceptionHandle>


+ (instancetype)shareExceptionProxy;


#pragma mark - Handle crash interface

/**
 Hold the JJExceptionHandle interface object
 */
@property(nonatomic,readwrite,weak)id<JJExceptionHandle> delegate;

/**
 Setting hook excpetion status,default value is NO
 */
@property(nonatomic,readwrite,assign)BOOL isProtectException;

/**
 If exceptionWhenTerminate YES,the exception will stop application
 If exceptionWhenTerminate NO,the exception only show log on the console, will not stop the application
 Default value:NO
 */
@property(nonatomic,readwrite,assign)BOOL exceptionWhenTerminate;

/**
 Setting exceptionGuardCategory
 @see JJExceptionGuardCategory
 */
@property(nonatomic,readwrite,assign)JJExceptionGuardCategory exceptionGuardCategory;

@end

/**
 Runtime gate consulted at the top of every hook.

 Hooks are installed once and stay installed, so this is what makes
 startGuardException / stopGuardException / configExceptionCategory take effect
 immediately instead of only at launch. It also lets a host app enable or disable
 one category at a time without relaunching.

 @param category the category the calling hook belongs to
 @return YES when that category is both configured and currently protecting
 */
FOUNDATION_EXPORT BOOL JJExceptionGuardEnabled(JJExceptionGuardCategory category);

NS_ASSUME_NONNULL_END
