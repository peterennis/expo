/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ABI35_0_0RCTFontStyle) {
  ABI35_0_0RCTFontStyleUndefined = -1,
  ABI35_0_0RCTFontStyleNormal,
  ABI35_0_0RCTFontStyleItalic,
  ABI35_0_0RCTFontStyleOblique,
};

typedef NS_OPTIONS(NSInteger, ABI35_0_0RCTFontVariant) {
  ABI35_0_0RCTFontVariantUndefined = -1,
  ABI35_0_0RCTFontVariantDefault = 0,
  ABI35_0_0RCTFontVariantSmallCaps = 1 << 1,
  ABI35_0_0RCTFontVariantOldstyleNums = 1 << 2,
  ABI35_0_0RCTFontVariantLiningNums = 1 << 3,
  ABI35_0_0RCTFontVariantTabularNums = 1 << 4,
  ABI35_0_0RCTFontVariantProportionalNums = 1 << 5,
};

struct ABI35_0_0RCTFontProperties {
  NSString *family;
  CGFloat size;
  UIFontWeight weight;
  ABI35_0_0RCTFontStyle style;
  ABI35_0_0RCTFontVariant variant;
  CGFloat sizeMultiplier;
};

NS_ASSUME_NONNULL_END
