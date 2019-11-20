// Copyright 2016-present 650 Industries. All rights reserved.

#import <ABI36_0_0EXPermissions/ABI36_0_0EXRemoteNotificationPermissionRequester.h>
#import <ABI36_0_0UMCore/ABI36_0_0UMUtilities.h>

NSString * const ABI36_0_0EXAppDidRegisterForRemoteNotificationsNotificationName = @"kEXAppDidRegisterForRemoteNotificationsNotification";

@interface ABI36_0_0EXRemoteNotificationPermissionRequester ()

@property (nonatomic, strong) ABI36_0_0UMPromiseResolveBlock resolve;
@property (nonatomic, strong) ABI36_0_0UMPromiseRejectBlock reject;
@property (nonatomic, assign) BOOL remoteNotificationsRegistrationIsPending;
@property (nonatomic, weak) ABI36_0_0EXUserNotificationPermissionRequester* userNotificationPermissionRequester;
@property (nonatomic, weak) dispatch_queue_t methodQueue;

@end

@implementation ABI36_0_0EXRemoteNotificationPermissionRequester

+ (NSString *)permissionType
{
  return @"notifications";
}

- (instancetype)initWithUserNotificationPermissionRequester:(ABI36_0_0EXUserNotificationPermissionRequester *)userNotificationPermissionRequester
                                            withMethodQueue:(dispatch_queue_t)methodQueue
{
  if (self = [super init]) {
    _remoteNotificationsRegistrationIsPending = NO;
    _userNotificationPermissionRequester = userNotificationPermissionRequester;
    _methodQueue = methodQueue;
  }
  return self;
}

- (NSDictionary *)getPermissions
{
  __block ABI36_0_0UMPermissionStatus status;
  [ABI36_0_0UMUtilities performSynchronouslyOnMainThread:^{
    status = (ABI36_0_0UMSharedApplication().isRegisteredForRemoteNotifications) ?
    ABI36_0_0UMPermissionStatusGranted :
    ABI36_0_0UMPermissionStatusUndetermined;
  }];
  NSMutableDictionary *permissions = [[_userNotificationPermissionRequester getPermissions] mutableCopy];
  
  [permissions setValuesForKeysWithDictionary:@{
                                                @"status": @(status),

                                                }];
  return permissions;
}

- (void)requestPermissionsWithResolver:(ABI36_0_0UMPromiseResolveBlock)resolve rejecter:(ABI36_0_0UMPromiseRejectBlock)reject
{
  if (_resolve != nil || _reject != nil) {
    reject(@"E_AWAIT_PROMISE", @"Another request for the same permission is already being handled.", nil);
    return;
  }

  _resolve = resolve;
  _reject = reject;

  BOOL __block isRegisteredForRemoteNotifications = NO;
  [ABI36_0_0UMUtilities performSynchronouslyOnMainThread:^{
    isRegisteredForRemoteNotifications = ABI36_0_0UMSharedApplication().isRegisteredForRemoteNotifications;
  }];

  if (isRegisteredForRemoteNotifications) {
    // resolve immediately if already registered
    [self _maybeConsumeResolverWithCurrentPermissions];
  } else {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleDidRegisterForRemoteNotifications:)
                                                 name:ABI36_0_0EXAppDidRegisterForRemoteNotificationsNotificationName
                                               object:nil];
     ABI36_0_0UM_WEAKIFY(self)
    [_userNotificationPermissionRequester requestPermissionsWithResolver:^(NSDictionary *permission){
      ABI36_0_0UM_STRONGIFY(self)
      ABI36_0_0UMPermissionStatus localNotificationsStatus = [[permission objectForKey:@"status"] intValue];
      // We may assume that `ABI36_0_0EXLocalNotificationRequester`'s permission request will always finish
      // when the user responds to the dialog or has already responded in the past.
      // However, `UIApplication.registerForRemoteNotification` results in calling
      // `application:didRegisterForRemoteNotificationsWithDeviceToken:` or
      // `application:didFailToRegisterForRemoteNotificationsWithError:` on the application delegate
      // ONLY when the notifications are enabled in settings (by allowing sound, alerts or app badge).
      // So, when the local notifications are disabled, the application delegate's callbacks will not be called instantly.
      if (localNotificationsStatus == ABI36_0_0UMPermissionStatusDenied) {
        [self _clearObserver];
        [self _maybeConsumeResolverWithCurrentPermissions];
      } else {
        self.remoteNotificationsRegistrationIsPending = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
          [ABI36_0_0UMSharedApplication() registerForRemoteNotifications];
        });
      }
    } rejecter:^(NSString *code, NSString *message, NSError *error){
      [self _clearObserver];
      if (self.reject) {
        self.reject(code, message, error);
      }
    }];
  }
}

- (void)dealloc
{
  [self _clearObserver];
}

- (void)_handleDidRegisterForRemoteNotifications:(__unused NSNotification *)notif
{
  [self _clearObserver];
  ABI36_0_0UM_WEAKIFY(self)
  dispatch_async(_methodQueue, ^{
    ABI36_0_0UM_STRONGIFY(self)
    [self _maybeConsumeResolverWithCurrentPermissions];
  });
}

- (void)_clearObserver
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  _remoteNotificationsRegistrationIsPending = NO;
}

- (void)_maybeConsumeResolverWithCurrentPermissions
{
  if (!_remoteNotificationsRegistrationIsPending) {
    if (_resolve) {
      _resolve([self getPermissions]);
      _resolve = nil;
      _reject = nil;
    }
  }
}

@end
