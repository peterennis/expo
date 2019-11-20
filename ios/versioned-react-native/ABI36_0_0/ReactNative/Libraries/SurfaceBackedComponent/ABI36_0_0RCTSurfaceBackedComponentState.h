/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

@class ABI36_0_0RCTSurface;

@interface ABI36_0_0RCTSurfaceBackedComponentState: NSObject

@property (atomic, readonly, strong) ABI36_0_0RCTSurface *surface;

+ (instancetype)newWithSurface:(ABI36_0_0RCTSurface *)surface;

@end
