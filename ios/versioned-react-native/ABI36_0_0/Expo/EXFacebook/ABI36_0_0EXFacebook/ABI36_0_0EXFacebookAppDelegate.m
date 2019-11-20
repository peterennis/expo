// Copyright 2016-present 650 Industries. All rights reserved.

#import <ABI36_0_0EXFacebook/ABI36_0_0EXFacebookAppDelegate.h>
#import <ABI36_0_0EXFacebook/ABI36_0_0EXFacebook.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ABI36_0_0UMCore/ABI36_0_0UMAppDelegateWrapper.h>
#import <objc/runtime.h>

@protocol ABI36_0_0EXOverriddingFBSDKInternalUtility <NSObject>

- (BOOL)isRegisteredURLScheme:(NSString *)urlScheme;

@end

static BOOL isRegisteredURLScheme(id self, SEL _cmd, NSString *urlScheme)
{
  // copied from FBSDKInternalUtility.h
  // !!!: Make FB SDK think we can open fb<app id>:// urls
  return ![@[@"fbauth2", @"fbapi", @"fb-messenger-share-api", @"fbshareextension"] containsObject:urlScheme];
}

@implementation ABI36_0_0EXFacebookAppDelegate

ABI36_0_0UM_REGISTER_SINGLETON_MODULE(ABI36_0_0EXFacebookAppDelegate)

- (instancetype)init
{
  if (self = [super init]) {
    // !!!: Make FB SDK think we can open fb<app id>:// urls
    Class internalUtilityClass = NSClassFromString(@"FBSDKInternalUtility");
    Method isRegisteredURLSchemeMethod = class_getClassMethod(internalUtilityClass, @selector(isRegisteredURLScheme:));
    method_setImplementation(isRegisteredURLSchemeMethod, (IMP)isRegisteredURLScheme);
  }
  return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
   return [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
  if ([[FBSDKApplicationDelegate sharedInstance] application:app
                                                     openURL:url
                                                     options:options]) {
    return YES;
  }

  return NO;
}

@end
