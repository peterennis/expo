// Copyright © 2019-present 650 Industries. All rights reserved.

#if __has_include(<ABI36_0_0EXSecureStore/ABI36_0_0EXSecureStore.h>)
#import "ABI36_0_0EXScopedSecureStore.h"

@interface ABI36_0_0EXSecureStore (Protected)

- (NSString *)validatedKey:(NSString *)key;

@end

@interface ABI36_0_0EXScopedSecureStore ()

@property (strong, nonatomic) NSString *experienceId;

@end

@implementation ABI36_0_0EXScopedSecureStore

- (instancetype)initWithExperienceId:(NSString *)experienceId
{
  if (self = [super init]) {
    _experienceId = experienceId;
  }
  return self;
}

- (NSString *)validatedKey:(NSString *)key {
  if (![super validatedKey:key]) {
    return nil;
  }

  return [NSString stringWithFormat:@"%@-%@", _experienceId, key];
}

@end
#endif
