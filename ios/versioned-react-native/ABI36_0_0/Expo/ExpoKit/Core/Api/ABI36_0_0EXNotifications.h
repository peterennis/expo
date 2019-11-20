// Copyright 2016-present 650 Industries. All rights reserved.

#import <UserNotifications/UserNotifications.h>
#import "ABI36_0_0EXScopedBridgeModule.h"
#import "ABI36_0_0EXScopedModuleRegistry.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ABI36_0_0EXUserNotificationCenterService

- (void)requestAuthorizationWithOptions:(UNAuthorizationOptions)options completionHandler:(void (^)(BOOL granted, NSError *__nullable error))completionHandler;

- (void)setNotificationCategories:(NSSet<UNNotificationCategory *> *)categories;
- (void)getNotificationCategoriesWithCompletionHandler:(void(^)(NSSet<UNNotificationCategory *> *categories))completionHandler;

- (void)getNotificationSettingsWithCompletionHandler:(void(^)(UNNotificationSettings *settings))completionHandler;

- (void)addNotificationRequest:(UNNotificationRequest *)request withCompletionHandler:(nullable void(^)(NSError *__nullable error))completionHandler;

- (void)getPendingNotificationRequestsWithCompletionHandler:(void(^)(NSArray<UNNotificationRequest *> *requests))completionHandler;
- (void)removePendingNotificationRequestsWithIdentifiers:(NSArray<NSString *> *)identifiers;
- (void)removeAllPendingNotificationRequests;

@end

@protocol ABI36_0_0EXNotificationsScopedModuleDelegate

- (NSString *)apnsTokenStringForScopedModule:(id)scopedModule;
- (void)getExpoPushTokenForScopedModule:(id)scopedModule
                      completionHandler:(void (^)(NSString * _Nullable pushToken, NSError * _Nullable error))handler;

@end

@protocol ABI36_0_0EXNotificationsIdentifiersManager

- (NSString *)internalIdForIdentifier:(NSString *)identifier experienceId:(NSString *)experienceId;
- (NSString *)exportedIdForInternalIdentifier:(NSString *)identifier;

@end

@interface ABI36_0_0EXNotifications : ABI36_0_0EXScopedBridgeModule

@end

NS_ASSUME_NONNULL_END
