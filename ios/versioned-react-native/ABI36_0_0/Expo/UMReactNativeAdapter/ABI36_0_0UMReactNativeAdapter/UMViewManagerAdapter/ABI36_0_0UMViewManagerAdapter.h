// Copyright 2018-present 650 Industries. All rights reserved.

#import <ABI36_0_0React/ABI36_0_0RCTViewManager.h>
#import <ABI36_0_0UMCore/ABI36_0_0UMViewManager.h>
#import <ABI36_0_0UMReactNativeAdapter/ABI36_0_0UMBridgeModule.h>
#import <ABI36_0_0UMReactNativeAdapter/ABI36_0_0UMNativeModulesProxy.h>

// ABI36_0_0UMViewManagerAdapter is an ABI36_0_0RN wrapper around ABI36_0_0UMCore's ABI36_0_0UMViewManager.
// For each exported view manager is it subclassed so that ABI36_0_0React Native
// can get proper module name (which is returned by a class method).
//
// Instead of instantiating the subclass by yourself,
// use ABI36_0_0UMViewManagerAdapterClassesRegistry's
// viewManagerAdapterClassForViewManager:.

@interface ABI36_0_0UMViewManagerAdapter : ABI36_0_0RCTViewManager

- (instancetype)initWithViewManager:(ABI36_0_0UMViewManager *)viewManager;

@end
