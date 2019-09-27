#import <ABI35_0_0EXAdsFacebook/ABI35_0_0EXAdIconViewManager.h>

@implementation ABI35_0_0EXAdIconViewManager

ABI35_0_0UM_EXPORT_MODULE(AdIconViewManager)

- (NSString *)viewName
{
  return @"AdIconView";
}

- (UIView *)view
{
  return [[FBAdIconView alloc] init];
}

@end
