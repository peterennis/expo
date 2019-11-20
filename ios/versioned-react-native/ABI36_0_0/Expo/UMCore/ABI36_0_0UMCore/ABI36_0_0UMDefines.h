// Copyright © 2018 650 Industries. All rights reserved.

#define ABI36_0_0UM_EXPORTED_METHODS_PREFIX __um_export__
#define ABI36_0_0UM_PROPSETTERS_PREFIX __um_set__

#define ABI36_0_0UM_DO_CONCAT(A, B) A ## B
#define ABI36_0_0UM_CONCAT(A, B) ABI36_0_0UM_DO_CONCAT(A, B)

#define ABI36_0_0UM_EXPORT_METHOD_AS(external_name, method) \
  _UM_EXTERN_METHOD(external_name, method) \
  - (void)method

#define _UM_EXTERN_METHOD(external_name, method) \
  + (const ABI36_0_0UMMethodInfo *)ABI36_0_0UM_CONCAT(ABI36_0_0UM_EXPORTED_METHODS_PREFIX, ABI36_0_0UM_CONCAT(external_name, ABI36_0_0UM_CONCAT(__LINE__, __COUNTER__))) { \
  static ABI36_0_0UMMethodInfo config = {#external_name, #method}; \
  return &config; \
  }

#define ABI36_0_0UM_VIEW_PROPERTY(external_name, type, viewClass) \
  - (void)ABI36_0_0UM_CONCAT(ABI36_0_0UM_PROPSETTERS_PREFIX, external_name):(type)value view:(viewClass *)view

#define _UM_DEFINE_CUSTOM_LOAD(_custom_load_code) \
  extern void ABI36_0_0UMRegisterModule(Class); \
  + (void)load { \
    ABI36_0_0UMRegisterModule(self); \
    _custom_load_code \
  }

#define ABI36_0_0UM_EXPORT_MODULE_WITH_CUSTOM_LOAD(external_name, _custom_load_code) \
  _UM_DEFINE_CUSTOM_LOAD(_custom_load_code) \
  + (const NSString *)exportedModuleName { return @#external_name; }

#define ABI36_0_0UM_EXPORT_MODULE(external_name) \
  ABI36_0_0UM_EXPORT_MODULE_WITH_CUSTOM_LOAD(external_name,)

#define ABI36_0_0UM_REGISTER_MODULE(_custom_load_code) \
  _UM_DEFINE_CUSTOM_LOAD(_custom_load_code)

#define ABI36_0_0UM_REGISTER_SINGLETON_MODULE_WITH_CUSTOM_LOAD(singleton_name, _custom_load_code) \
  extern void ABI36_0_0UMRegisterSingletonModule(Class); \
  + (const NSString *)name { \
    return @#singleton_name; \
  } \
  \
  + (void)load { \
    ABI36_0_0UMRegisterSingletonModule(self); \
    _custom_load_code \
  }

#define ABI36_0_0UM_REGISTER_SINGLETON_MODULE(singleton_name) \
  ABI36_0_0UM_REGISTER_SINGLETON_MODULE_WITH_CUSTOM_LOAD(singleton_name,)

#define ABI36_0_0UM_WEAKIFY(var) \
__weak typeof(var) ABI36_0_0UMWeak_##var = var;

#define ABI36_0_0UM_STRONGIFY(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = ABI36_0_0UMWeak_##var; \
_Pragma("clang diagnostic pop")

#define ABI36_0_0UM_ENSURE_STRONGIFY(var) \
ABI36_0_0UM_STRONGIFY(var); \
if (var == nil) { return; }

// Converts nil -> [NSNull null]
#define ABI36_0_0UMNullIfNil(value) (value ?: [NSNull null])

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef struct ABI36_0_0UMMethodInfo {
  const char *const jsName;
  const char *const objcName;
} ABI36_0_0UMMethodInfo;

typedef struct ABI36_0_0UMModuleInfo {
  const char *const jsName;
  const char *const internalName;
} ABI36_0_0UMModuleInfo;

typedef void (^ABI36_0_0UMDirectEventBlock)(NSDictionary *body);
typedef void (^ABI36_0_0UMPromiseResolveBlock)(id result);
typedef void (^ABI36_0_0UMPromiseRejectBlock)(NSString *code, NSString *message, NSError *error);

#pragma mark - Externs

// These should be defined by the concrete platform adapter
extern void ABI36_0_0UMLogInfo(NSString *format, ...);
extern void ABI36_0_0UMLogWarn(NSString *format, ...);
extern void ABI36_0_0UMLogError(NSString *format, ...);
extern void ABI36_0_0UMFatal(NSError *);
extern NSError * ABI36_0_0UMErrorWithMessage(NSString *);
extern UIApplication *ABI36_0_0UMSharedApplication(void);
