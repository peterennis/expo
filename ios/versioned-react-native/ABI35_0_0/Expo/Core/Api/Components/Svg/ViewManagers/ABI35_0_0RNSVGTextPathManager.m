/**
 * Copyright (c) 2015-present, Horcrux.
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI35_0_0RNSVGTextPathManager.h"

#import "ABI35_0_0RNSVGTextPath.h"

@implementation ABI35_0_0RNSVGTextPathManager

ABI35_0_0RCT_EXPORT_MODULE()

- (ABI35_0_0RNSVGRenderable *)node
{
  return [ABI35_0_0RNSVGTextPath new];
}

ABI35_0_0RCT_EXPORT_VIEW_PROPERTY(href, NSString)
ABI35_0_0RCT_EXPORT_VIEW_PROPERTY(side, NSString)
ABI35_0_0RCT_EXPORT_VIEW_PROPERTY(method, NSString)
ABI35_0_0RCT_EXPORT_VIEW_PROPERTY(midLine, NSString)
ABI35_0_0RCT_EXPORT_VIEW_PROPERTY(spacing, NSString)
ABI35_0_0RCT_EXPORT_VIEW_PROPERTY(startOffset, ABI35_0_0RNSVGLength*)

@end
