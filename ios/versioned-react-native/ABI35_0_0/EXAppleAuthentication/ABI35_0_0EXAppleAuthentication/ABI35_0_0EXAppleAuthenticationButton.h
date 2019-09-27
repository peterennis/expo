// Copyright 2018-present 650 Industries. All rights reserved.

#import <ABI35_0_0UMCore/ABI35_0_0UMUtilities.h>

@import AuthenticationServices;

API_AVAILABLE(ios(13.0))
@interface ABI35_0_0EXAppleAuthenticationButton : ASAuthorizationAppleIDButton

@property (nonatomic, copy) ABI35_0_0UMDirectEventBlock onButtonPress;

@end
