/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI35_0_0RCTSwitch.h"

#import "ABI35_0_0RCTEventDispatcher.h"
#import "UIView+ReactABI35_0_0.h"

@implementation ABI35_0_0RCTSwitch

- (void)setOn:(BOOL)on animated:(BOOL)animated {
  _wasOn = on;
  [super setOn:on animated:animated];
}

@end
