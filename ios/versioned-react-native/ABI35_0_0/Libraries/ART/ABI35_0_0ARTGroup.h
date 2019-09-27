/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "ABI35_0_0ARTContainer.h"
#import "ABI35_0_0ARTNode.h"

@interface ABI35_0_0ARTGroup : ABI35_0_0ARTNode <ABI35_0_0ARTContainer>

@property (nonatomic, assign) CGRect clipping;

@end
