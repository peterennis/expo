/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <ReactABI35_0_0/ABI35_0_0RCTMountItemProtocol.h>
#import <ReactABI35_0_0/ABI35_0_0RCTPrimitives.h>

NS_ASSUME_NONNULL_BEGIN

@class ABI35_0_0RCTComponentViewRegistry;

/**
 * Inserts a component view into another component view.
 */
@interface ABI35_0_0RCTInsertMountItem : NSObject <ABI35_0_0RCTMountItemProtocol>

- (instancetype)initWithChildTag:(ReactABI35_0_0Tag)childTag
                       parentTag:(ReactABI35_0_0Tag)parentTag
                           index:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
