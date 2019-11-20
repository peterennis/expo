// Copyright 2015-present 650 Industries. All rights reserved.

#import <ABI36_0_0React/ABI36_0_0RCTDevSettings.h>

@interface ABI36_0_0EXDevSettings : ABI36_0_0RCTDevSettings

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithExperienceId:(NSString *)experienceId
                       isDevelopment:(BOOL)isDevelopment NS_DESIGNATED_INITIALIZER;

@end
