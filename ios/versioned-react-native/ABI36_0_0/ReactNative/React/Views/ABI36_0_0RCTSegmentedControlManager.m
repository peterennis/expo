/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI36_0_0RCTSegmentedControlManager.h"

#import "ABI36_0_0RCTBridge.h"
#import "ABI36_0_0RCTConvert.h"
#import "ABI36_0_0RCTSegmentedControl.h"

@implementation ABI36_0_0RCTSegmentedControlManager

ABI36_0_0RCT_EXPORT_MODULE()

- (UIView *)view
{
  return [ABI36_0_0RCTSegmentedControl new];
}

ABI36_0_0RCT_EXPORT_VIEW_PROPERTY(values, NSArray<NSString *>)
ABI36_0_0RCT_EXPORT_VIEW_PROPERTY(selectedIndex, NSInteger)
ABI36_0_0RCT_EXPORT_VIEW_PROPERTY(tintColor, UIColor)
ABI36_0_0RCT_EXPORT_VIEW_PROPERTY(momentary, BOOL)
ABI36_0_0RCT_EXPORT_VIEW_PROPERTY(enabled, BOOL)
ABI36_0_0RCT_EXPORT_VIEW_PROPERTY(onChange, ABI36_0_0RCTBubblingEventBlock)

@end
