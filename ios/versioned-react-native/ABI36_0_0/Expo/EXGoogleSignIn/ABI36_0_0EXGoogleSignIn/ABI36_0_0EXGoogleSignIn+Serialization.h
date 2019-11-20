// Copyright 2018-present 650 Industries. All rights reserved.

#import <Foundation/Foundation.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <ABI36_0_0EXGoogleSignIn/ABI36_0_0EXGoogleSignIn.h>

@interface ABI36_0_0EXGoogleSignIn (Serialization)

+ (NSDictionary *)jsonFromGIDSignIn:(GIDSignIn *)input;
+ (NSDictionary *)jsonFromGIDGoogleUser:(GIDGoogleUser *)input;
+ (NSDictionary *)jsonFromGIDProfileData:(GIDProfileData *)input;
+ (NSDictionary *)jsonFromGIDAuthentication:(GIDAuthentication *)input;
+ (NSString *)jsonFromGIDSignInErrorCode:(GIDSignInErrorCode)input;

@end
