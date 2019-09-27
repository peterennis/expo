/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <ReactABI35_0_0/imagemanager/ImageRequest.h>
#import <ReactABI35_0_0/imagemanager/primitives.h>

NS_ASSUME_NONNULL_BEGIN

@class ABI35_0_0RCTImageLoader;

/**
 * iOS-specific ImageManager.
 */
@interface ABI35_0_0RCTImageManager : NSObject

- (instancetype)initWithImageLoader:(ABI35_0_0RCTImageLoader *)imageLoader;

- (facebook::ReactABI35_0_0::ImageRequest)requestImage:
    (const facebook::ReactABI35_0_0::ImageSource &)imageSource;

@end

NS_ASSUME_NONNULL_END
