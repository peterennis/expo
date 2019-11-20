/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <memory>

#import <Foundation/Foundation.h>

#import <ABI36_0_0React/ABI36_0_0RCTBridge.h>
#import <ABI36_0_0React/ABI36_0_0RCTBridgeModule.h>
#import <ABI36_0_0React/ABI36_0_0RCTModuleMethod.h>
#import <ABI36_0_0ReactCommon/ABI36_0_0JSCallInvoker.h>
#import <ABI36_0_0ReactCommon/ABI36_0_0TurboModule.h>
#import <ABI36_0_0cxxreact/ABI36_0_0MessageQueueThread.h>
#import <string>
#import <unordered_map>

#define ABI36_0_0RCT_IS_TURBO_MODULE_CLASS(klass) \
  ((ABI36_0_0RCTTurboModuleEnabled() && [(klass) conformsToProtocol:@protocol(ABI36_0_0RCTTurboModule)]))
#define ABI36_0_0RCT_IS_TURBO_MODULE_INSTANCE(module) ABI36_0_0RCT_IS_TURBO_MODULE_CLASS([(module) class])

namespace ABI36_0_0facebook {
namespace ABI36_0_0React {

class Instance;

/**
 * ObjC++ specific TurboModule base class.
 */
class JSI_EXPORT ObjCTurboModule : public TurboModule {
 public:
  ObjCTurboModule(const std::string &name, id<ABI36_0_0RCTTurboModule> instance, std::shared_ptr<JSCallInvoker> jsInvoker);

  jsi::Value invokeObjCMethod(
      jsi::Runtime &runtime,
      TurboModuleMethodValueKind valueKind,
      const std::string &methodName,
      SEL selector,
      const jsi::Value *args,
      size_t count);

  id<ABI36_0_0RCTTurboModule> instance_;

 protected:
  void setMethodArgConversionSelector(NSString *methodName, int argIndex, NSString *fnName);

 private:
  /**
   * TODO(ramanpreet):
   * Investigate an optimization that'll let us get rid of this NSMutableDictionary.
   */
  NSMutableDictionary<NSString *, NSMutableArray *> *methodArgConversionSelectors_;
  NSDictionary<NSString *, NSArray<NSString *> *> *methodArgumentTypeNames_;
  NSString *getArgumentTypeName(NSString *methodName, int argIndex);

  NSInvocation *getMethodInvocation(
      jsi::Runtime &runtime,
      TurboModuleMethodValueKind valueKind,
      const id<ABI36_0_0RCTTurboModule> module,
      std::shared_ptr<JSCallInvoker> jsInvoker,
      const std::string &methodName,
      SEL selector,
      const jsi::Value *args,
      size_t count,
      NSMutableArray *retainedObjectsForInvocation);

  BOOL hasMethodArgConversionSelector(NSString *methodName, int argIndex);
  SEL getMethodArgConversionSelector(NSString *methodName, int argIndex);
};

} // namespace ABI36_0_0React
} // namespace ABI36_0_0facebook

@protocol ABI36_0_0RCTTurboModule <NSObject>
@optional
/**
 * Used by TurboModules to get access to other TurboModules.
 *
 * Usage:
 * Place `@synthesize turboModuleLookupDelegate = _turboModuleLookupDelegate`
 * in the @implementation section of your TurboModule.
 */
@property (nonatomic, weak) id<ABI36_0_0RCTTurboModuleLookupDelegate> turboModuleLookupDelegate;

@optional
// This should be required, after migration is done.
- (std::shared_ptr<ABI36_0_0facebook::ABI36_0_0React::TurboModule>)getTurboModuleWithJsInvoker:
    (std::shared_ptr<ABI36_0_0facebook::ABI36_0_0React::JSCallInvoker>)jsInvoker;

@end

// TODO: Consolidate this extension with the one in ABI36_0_0RCTSurfacePresenter.
@interface ABI36_0_0RCTBridge ()

- (std::weak_ptr<ABI36_0_0facebook::ABI36_0_0React::Instance>)ABI36_0_0ReactInstance;

@end
