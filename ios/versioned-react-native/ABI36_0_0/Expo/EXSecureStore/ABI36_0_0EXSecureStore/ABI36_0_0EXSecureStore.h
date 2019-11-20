//  Copyright © 2018 650 Industries. All rights reserved.

#import <ABI36_0_0UMCore/ABI36_0_0UMExportedModule.h>
#import <ABI36_0_0UMCore/ABI36_0_0UMModuleRegistryConsumer.h>

typedef NS_ENUM(NSInteger, ABI36_0_0EXSecureStoreAccessible) {
  ABI36_0_0EXSecureStoreAccessibleAfterFirstUnlock = 0,
  ABI36_0_0EXSecureStoreAccessibleAfterFirstUnlockThisDeviceOnly = 1,
  ABI36_0_0EXSecureStoreAccessibleAlways = 2,
  ABI36_0_0EXSecureStoreAccessibleWhenPasscodeSetThisDeviceOnly = 3,
  ABI36_0_0EXSecureStoreAccessibleAlwaysThisDeviceOnly = 4,
  ABI36_0_0EXSecureStoreAccessibleWhenUnlocked = 5,
  ABI36_0_0EXSecureStoreAccessibleWhenUnlockedThisDeviceOnly = 6
};

@interface ABI36_0_0EXSecureStore : ABI36_0_0UMExportedModule

@end
