/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI35_0_0RCTSwitchManager.h"

#import "ABI35_0_0RCTBridge.h"
#import "ABI35_0_0RCTEventDispatcher.h"
#import "ABI35_0_0RCTSwitch.h"
#import "UIView+ReactABI35_0_0.h"

@implementation ABI35_0_0RCTSwitchManager

ABI35_0_0RCT_EXPORT_MODULE()

- (UIView *)view
{
  ABI35_0_0RCTSwitch *switcher = [ABI35_0_0RCTSwitch new];
  [switcher addTarget:self
               action:@selector(onChange:)
     forControlEvents:UIControlEventValueChanged];
  return switcher;
}

- (void)onChange:(ABI35_0_0RCTSwitch *)sender
{
  if (sender.wasOn != sender.on) {
    if (sender.onChange) {
      sender.onChange(@{ @"value": @(sender.on) });
    }
    sender.wasOn = sender.on;
  }
}

ABI35_0_0RCT_EXPORT_VIEW_PROPERTY(onTintColor, UIColor);
ABI35_0_0RCT_EXPORT_VIEW_PROPERTY(tintColor, UIColor);
ABI35_0_0RCT_EXPORT_VIEW_PROPERTY(thumbTintColor, UIColor);
ABI35_0_0RCT_REMAP_VIEW_PROPERTY(value, on, BOOL);
ABI35_0_0RCT_EXPORT_VIEW_PROPERTY(onChange, ABI35_0_0RCTBubblingEventBlock);
ABI35_0_0RCT_CUSTOM_VIEW_PROPERTY(disabled, BOOL, ABI35_0_0RCTSwitch)
{
  if (json) {
    view.enabled = !([ABI35_0_0RCTConvert BOOL:json]);
  } else {
    view.enabled = defaultView.enabled;
  }
}
ABI35_0_0RCT_REMAP_VIEW_PROPERTY(thumbColor, thumbTintColor, UIColor);
ABI35_0_0RCT_REMAP_VIEW_PROPERTY(trackColorForFalse, tintColor, UIColor);
ABI35_0_0RCT_REMAP_VIEW_PROPERTY(trackColorForTrue, onTintColor, UIColor);

@end
