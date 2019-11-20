// Copyright © 2018 650 Industries. All rights reserved.

#import <UIKit/UIKit.h>
#import <ABI36_0_0UMCore/ABI36_0_0UMInternalModule.h>
#import <ABI36_0_0UMCore/ABI36_0_0UMUtilitiesInterface.h>
#import <ABI36_0_0UMCore/ABI36_0_0UMModuleRegistryConsumer.h>

@interface ABI36_0_0UMUtilities : NSObject <ABI36_0_0UMInternalModule, ABI36_0_0UMUtilitiesInterface, ABI36_0_0UMModuleRegistryConsumer>

+ (void)performSynchronouslyOnMainThread:(nonnull void (^)(void))block;
+ (CGFloat)screenScale;
+ (nullable UIColor *)UIColor:(nullable id)json;
+ (nullable NSDate *)NSDate:(nullable id)json;
+ (nonnull NSString *)hexStringWithCGColor:(nonnull CGColorRef)color;

- (nullable UIViewController *)currentViewController;
- (nullable NSDictionary *)launchOptions;

@end
