/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI36_0_0RCTTurboModuleManager.h"

#import <atomic>
#import <cassert>
#import <mutex>

#import <ABI36_0_0React/ABI36_0_0RCTBridge+Private.h>
#import <ABI36_0_0React/ABI36_0_0RCTBridgeModule.h>
#import <ABI36_0_0React/ABI36_0_0RCTCxxModule.h>
#import <ABI36_0_0React/ABI36_0_0RCTLog.h>
#import <ABI36_0_0React/ABI36_0_0RCTPerformanceLogger.h>
#import <ABI36_0_0ReactCommon/ABI36_0_0BridgeJSCallInvoker.h>
#import <ABI36_0_0ReactCommon/ABI36_0_0TurboCxxModule.h>
#import <ABI36_0_0ReactCommon/ABI36_0_0TurboModuleBinding.h>

using namespace ABI36_0_0facebook;

// Fallback lookup since ABI36_0_0RCT class prefix is sometimes stripped in the existing NativeModule system.
// This will be removed in the future.
static Class getFallbackClassFromName(const char *name)
{
  Class moduleClass = NSClassFromString([NSString stringWithUTF8String:name]);
  if (!moduleClass) {
    moduleClass = NSClassFromString([NSString stringWithFormat:@"ABI36_0_0RCT%s", name]);
  }
  return moduleClass;
}

@implementation ABI36_0_0RCTTurboModuleManager {
  jsi::Runtime *_runtime;
  std::shared_ptr<ABI36_0_0facebook::ABI36_0_0React::JSCallInvoker> _jsInvoker;
  std::shared_ptr<ABI36_0_0React::TurboModuleBinding> _binding;
  __weak id<ABI36_0_0RCTTurboModuleManagerDelegate> _delegate;
  __weak ABI36_0_0RCTBridge *_bridge;
  /**
   * TODO(T48018690):
   * All modules are currently long-lived.
   * We need to come up with a mechanism to allow modules to specify whether
   * they want to be long-lived or short-lived.
   */
  std::unordered_map<std::string, id<ABI36_0_0RCTTurboModule>> _rctTurboModuleCache;
  std::unordered_map<std::string, std::shared_ptr<ABI36_0_0React::TurboModule>> _turboModuleCache;

  /**
   * _rctTurboModuleCache can be accessed by multiple threads at once via
   * the provideABI36_0_0RCTTurboModule method. This can lead to races. Therefore, we
   * need to protect access to this unordered_map.
   *
   * Note:
   * There's no need to protect access to _turboModuleCache because that cache
   * is only accessed within provideTurboModule, which is only invoked by the
   * JS thread.
   */
  std::mutex _rctTurboModuleCacheLock;
  std::atomic<bool> _invalidating;
}

- (instancetype)initWithBridge:(ABI36_0_0RCTBridge *)bridge delegate:(id<ABI36_0_0RCTTurboModuleManagerDelegate>)delegate
{
  if (self = [super init]) {
    _jsInvoker = std::make_shared<ABI36_0_0React::BridgeJSCallInvoker>(bridge.ABI36_0_0ReactInstance);
    _delegate = delegate;
    _bridge = bridge;
    _invalidating = false;

    // Necessary to allow NativeModules to lookup TurboModules
    [bridge setABI36_0_0RCTTurboModuleLookupDelegate:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bridgeWillInvalidateModules:)
                                                 name:ABI36_0_0RCTBridgeWillInvalidateModulesNotification
                                               object:_bridge.parentBridge];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bridgeDidInvalidateModules:)
                                                 name:ABI36_0_0RCTBridgeDidInvalidateModulesNotification
                                               object:_bridge.parentBridge];

    __weak __typeof(self) weakSelf = self;

    auto moduleProvider = [weakSelf](const std::string &name) -> std::shared_ptr<ABI36_0_0React::TurboModule> {
      if (!weakSelf) {
        return nullptr;
      }

      __strong __typeof(self) strongSelf = weakSelf;

      auto moduleName = name.c_str();
      auto moduleWasNotInitialized = ![strongSelf moduleIsInitialized:moduleName];
      if (moduleWasNotInitialized) {
        [strongSelf->_bridge.performanceLogger markStartForTag:ABI36_0_0RCTPLTurboModuleSetup];
      }

      /**
       * By default, all TurboModules are long-lived.
       * Additionally, if a TurboModule with the name `name` isn't found, then we
       * trigger an assertion failure.
       */
      auto turboModule = [strongSelf provideTurboModule:moduleName];

      if (moduleWasNotInitialized && [strongSelf moduleIsInitialized:moduleName]) {
        [strongSelf->_bridge.performanceLogger markStopForTag:ABI36_0_0RCTPLTurboModuleSetup];
        [strongSelf notifyAboutTurboModuleSetup:moduleName];
      }

      return turboModule;
    };

    _binding = std::make_shared<ABI36_0_0React::TurboModuleBinding>(moduleProvider);
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)notifyAboutTurboModuleSetup:(const char *)name
{
  NSString *moduleName = [[NSString alloc] initWithUTF8String:name];
  if (moduleName) {
    int64_t setupTime = [self->_bridge.performanceLogger durationForTag:ABI36_0_0RCTPLTurboModuleSetup];
    [[NSNotificationCenter defaultCenter] postNotificationName:ABI36_0_0RCTDidSetupModuleNotification
                                                        object:nil
                                                      userInfo:@{
                                                        ABI36_0_0RCTDidSetupModuleNotificationModuleNameKey : moduleName,
                                                        ABI36_0_0RCTDidSetupModuleNotificationSetupTimeKey : @(setupTime)
                                                      }];
  }
}

/**
 * Given a name for a TurboModule, return a C++ object which is the instance
 * of that TurboModule C++ class. This class wraps the TurboModule's ObjC instance.
 * If no TurboModule ObjC class exist with the provided name, abort program.
 *
 * Note: All TurboModule instances are cached, which means they're all long-lived
 * (for now).
 */

- (std::shared_ptr<ABI36_0_0React::TurboModule>)provideTurboModule:(const char *)moduleName
{
  auto turboModuleLookup = _turboModuleCache.find(moduleName);
  if (turboModuleLookup != _turboModuleCache.end()) {
    return turboModuleLookup->second;
  }

  /**
   * Step 1: Look for pure C++ modules.
   * Pure C++ modules get priority.
   */
  if ([_delegate respondsToSelector:@selector(getTurboModule:jsInvoker:)]) {
    auto turboModule = [_delegate getTurboModule:moduleName jsInvoker:_jsInvoker];
    if (turboModule != nullptr) {
      _turboModuleCache.insert({moduleName, turboModule});
      return turboModule;
    }
  }

  /**
   * Step 2: Look for platform-specific modules.
   */
  id<ABI36_0_0RCTTurboModule> module = [self provideABI36_0_0RCTTurboModule:moduleName];

  // If we request that a TurboModule be created, its respective ObjC class must exist
  // If the class doesn't exist, then provideABI36_0_0RCTTurboModule returns nil
  if (!module) {
    return nullptr;
  }

  Class moduleClass = [module class];

  // If ABI36_0_0RCTTurboModule supports creating its own C++ TurboModule object,
  // allow it to do so.
  if ([module respondsToSelector:@selector(getTurboModuleWithJsInvoker:)]) {
    auto turboModule = [module getTurboModuleWithJsInvoker:_jsInvoker];
    assert(turboModule != nullptr);
    _turboModuleCache.insert({moduleName, turboModule});
    return turboModule;
  }

  /**
   * Step 2c: If the moduleClass is a legacy CxxModule, return a TurboCxxModule instance that
   * wraps CxxModule.
   */
  if ([moduleClass isSubclassOfClass:ABI36_0_0RCTCxxModule.class]) {
    // Use TurboCxxModule compat class to wrap the CxxModule instance.
    // This is only for migration convenience, despite less performant.
    auto turboModule = std::make_shared<ABI36_0_0React::TurboCxxModule>([((ABI36_0_0RCTCxxModule *)module) createModule], _jsInvoker);
    _turboModuleCache.insert({moduleName, turboModule});
    return turboModule;
  }

  /**
   * Step 2d: Return an exact sub-class of ObjC TurboModule
   */
  auto turboModule = [_delegate getTurboModule:moduleName instance:module jsInvoker:_jsInvoker];
  if (turboModule != nullptr) {
    _turboModuleCache.insert({moduleName, turboModule});
  }
  return turboModule;
}

/**
 * Given a name for a TurboModule, return an ObjC object which is the instance
 * of that TurboModule ObjC class. If no TurboModule exist with the provided name,
 * return nil.
 *
 * Note: All TurboModule instances are cached, which means they're all long-lived
 * (for now).
 */
- (id<ABI36_0_0RCTTurboModule>)provideABI36_0_0RCTTurboModule:(const char *)moduleName
{
  Class moduleClass;
  id<ABI36_0_0RCTTurboModule> module = nil;

  {
    std::unique_lock<std::mutex> lock(_rctTurboModuleCacheLock);

    auto rctTurboModuleCacheLookup = _rctTurboModuleCache.find(moduleName);
    if (rctTurboModuleCacheLookup != _rctTurboModuleCache.end()) {
      return rctTurboModuleCacheLookup->second;
    }

    if (_invalidating) {
      // Don't allow creating new instances while invalidating.
      return nil;
    }

    /**
     * Step 2a: Resolve platform-specific class.
     */
    if ([_delegate respondsToSelector:@selector(getModuleClassFromName:)]) {
      moduleClass = [_delegate getModuleClassFromName:moduleName];
    }

    if (!moduleClass) {
      moduleClass = getFallbackClassFromName(moduleName);
    }

    if (![moduleClass conformsToProtocol:@protocol(ABI36_0_0RCTTurboModule)]) {
      return nil;
    }

    /**
     * Step 2b: Ask hosting application/delegate to instantiate this class
     */
    if ([_delegate respondsToSelector:@selector(getModuleInstanceFromClass:)]) {
      module = [_delegate getModuleInstanceFromClass:moduleClass];
    } else {
      module = [moduleClass new];
    }

    if ([module respondsToSelector:@selector(setTurboModuleLookupDelegate:)]) {
      [module setTurboModuleLookupDelegate:self];
    }

    _rctTurboModuleCache.insert({moduleName, module});
  }

  /**
   * It is reasonable for NativeModules to not want/need the bridge.
   * In such cases, they won't have `@synthesize bridge = _bridge` in their
   * implementation, and a `- (ABI36_0_0RCTBridge *) bridge { ... }` method won't be
   * generated by the ObjC runtime. The property will also not be backed
   * by an ivar, which makes writing to it unsafe. Therefore, we check if
   * this method exists to know if we can safely set the bridge to the
   * NativeModule.
   */
  if ([module respondsToSelector:@selector(bridge)] && _bridge) {
    /**
     * Just because a NativeModule has the `bridge` method, it doesn't mean
     * that it has synthesized the bridge in its implementation. Therefore,
     * we need to surround the code that sets the bridge to the NativeModule
     * inside a try/catch. This catches the cases where the NativeModule
     * author specifies a `bridge` method manually.
     */
    @try {
      /**
       * ABI36_0_0RCTBridgeModule declares the bridge property as readonly.
       * Therefore, when authors of NativeModules synthesize the bridge
       * via @synthesize bridge = bridge;, the ObjC runtime generates
       * only a - (ABI36_0_0RCTBridge *) bridge: { ... } method. No setter is
       * generated, so we have have to rely on the KVC API of ObjC to set
       * the bridge property of these NativeModules.
       */
      [(id)module setValue:_bridge forKey:@"bridge"];
    } @catch (NSException *exception) {
      ABI36_0_0RCTLogError(
          @"%@ has no setter or ivar for its bridge, which is not "
           "permitted. You must either @synthesize the bridge property, "
           "or provide your own setter method.",
          ABI36_0_0RCTBridgeModuleNameForClass(module));
    }
  }

  /**
   * Some modules need their own queues, but don't provide any, so we need to create it for them.
   * These modules typically have the following:
   *   `@synthesize methodQueue = _methodQueue`
   */
  if ([module respondsToSelector:@selector(methodQueue)]) {
    dispatch_queue_t methodQueue = [module performSelector:@selector(methodQueue)];
    if (!methodQueue) {
      NSString *moduleClassName = NSStringFromClass(module.class);
      NSString *queueName = [NSString stringWithFormat:@"com.facebook.ABI36_0_0React.%@Queue", moduleClassName];
      methodQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
      @try {
        [(id)module setValue:methodQueue forKey:@"methodQueue"];
      } @catch (NSException *exception) {
        ABI36_0_0RCTLogError(
            @"TM: %@ is returning nil for its methodQueue, which is not "
             "permitted. You must either return a pre-initialized "
             "queue, or @synthesize the methodQueue to let the bridge "
             "create a queue for you.",
            moduleClassName);
      }
    }
  }

  /**
   * Broadcast that this TurboModule was created.
   *
   * TODO(T41180176): Investigate whether we can get rid of this after all
   * TurboModules are rolled out
   */
  [[NSNotificationCenter defaultCenter]
      postNotificationName:ABI36_0_0RCTDidInitializeModuleNotification
                    object:_bridge
                  userInfo:@{@"module" : module, @"bridge" : ABI36_0_0RCTNullIfNil(_bridge.parentBridge)}];
  return module;
}

- (void)installJSBindingWithRuntime:(jsi::Runtime *)runtime
{
  _runtime = runtime;

  if (!_runtime) {
    // jsi::Runtime doesn't exist when attached to Chrome debugger.
    return;
  }

  ABI36_0_0React::TurboModuleBinding::install(*_runtime, _binding);
}

- (std::shared_ptr<ABI36_0_0facebook::ABI36_0_0React::TurboModule>)getModule:(const std::string &)name
{
  return _binding->getModule(name);
}

#pragma mark ABI36_0_0RCTTurboModuleLookupDelegate

- (id)moduleForName:(const char *)moduleName
{
  return [self moduleForName:moduleName warnOnLookupFailure:YES];
}

- (id)moduleForName:(const char *)moduleName warnOnLookupFailure:(BOOL)warnOnLookupFailure
{
  id<ABI36_0_0RCTTurboModule> module = [self provideABI36_0_0RCTTurboModule:moduleName];

  if (warnOnLookupFailure && !module) {
    ABI36_0_0RCTLogError(@"Unable to find module for %@", [NSString stringWithUTF8String:moduleName]);
  }

  return module;
}

- (BOOL)moduleIsInitialized:(const char *)moduleName
{
  std::unique_lock<std::mutex> lock(_rctTurboModuleCacheLock);
  return _rctTurboModuleCache.find(std::string(moduleName)) != _rctTurboModuleCache.end();
}

#pragma mark Invalidation logic

- (void)bridgeWillInvalidateModules:(NSNotification *)notification
{
  ABI36_0_0RCTBridge *bridge = notification.userInfo[@"bridge"];
  if (bridge != _bridge) {
    return;
  }

  _invalidating = true;
}

- (void)bridgeDidInvalidateModules:(NSNotification *)notification
{
  ABI36_0_0RCTBridge *bridge = notification.userInfo[@"bridge"];
  if (bridge != _bridge) {
    return;
  }

  std::unordered_map<std::string, id<ABI36_0_0RCTTurboModule>> rctCacheCopy;
  {
    std::unique_lock<std::mutex> lock(_rctTurboModuleCacheLock);
    rctCacheCopy.insert(_rctTurboModuleCache.begin(), _rctTurboModuleCache.end());
  }

  // Backward-compatibility: ABI36_0_0RCTInvalidating handling.
  dispatch_group_t moduleInvalidationGroup = dispatch_group_create();
  for (const auto &p : rctCacheCopy) {
    id<ABI36_0_0RCTTurboModule> module = p.second;
    if ([module respondsToSelector:@selector(invalidate)]) {
      if ([module respondsToSelector:@selector(methodQueue)]) {
        dispatch_queue_t methodQueue = [module performSelector:@selector(methodQueue)];
        if (methodQueue) {
          dispatch_group_enter(moduleInvalidationGroup);
          [bridge
              dispatchBlock:^{
                [((id<ABI36_0_0RCTInvalidating>)module) invalidate];
                dispatch_group_leave(moduleInvalidationGroup);
              }
                      queue:methodQueue];
          continue;
        }
      }
      [((id<ABI36_0_0RCTInvalidating>)module) invalidate];
    }
  }

  if (dispatch_group_wait(moduleInvalidationGroup, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC))) {
    ABI36_0_0RCTLogError(@"TurboModuleManager: Timed out waiting for modules to be invalidated");
  }

  {
    std::unique_lock<std::mutex> lock(_rctTurboModuleCacheLock);
    _rctTurboModuleCache.clear();
  }

  _turboModuleCache.clear();

  _binding->invalidate();
}

@end
