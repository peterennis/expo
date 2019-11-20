/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "ABI36_0_0ARTRenderable.h"
#import "ABI36_0_0ARTTextFrame.h"

@interface ABI36_0_0ARTText : ABI36_0_0ARTRenderable

@property (nonatomic, assign) CTTextAlignment alignment;
@property (nonatomic, assign) ABI36_0_0ARTTextFrame textFrame;

@end
