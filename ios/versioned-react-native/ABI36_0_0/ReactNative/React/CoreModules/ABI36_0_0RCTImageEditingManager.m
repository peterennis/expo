/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <ABI36_0_0React/ABI36_0_0RCTImageEditingManager.h>

#import <UIKit/UIKit.h>

#import <ABI36_0_0React/ABI36_0_0RCTConvert.h>
#import <ABI36_0_0React/ABI36_0_0RCTImageLoader.h>
#import <ABI36_0_0React/ABI36_0_0RCTImageStoreManager.h>
#import <ABI36_0_0React/ABI36_0_0RCTImageUtils.h>
#import <ABI36_0_0React/ABI36_0_0RCTImageLoaderProtocol.h>
#import <ABI36_0_0React/ABI36_0_0RCTLog.h>
#import <ABI36_0_0React/ABI36_0_0RCTUtils.h>

@implementation ABI36_0_0RCTImageEditingManager

ABI36_0_0RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

/**
 * Crops an image and adds the result to the image store.
 *
 * @param imageRequest An image URL
 * @param cropData Dictionary with `offset`, `size` and `displaySize`.
 *        `offset` and `size` are relative to the full-resolution image size.
 *        `displaySize` is an optimization - if specified, the image will
 *        be scaled down to `displaySize` rather than `size`.
 *        All units are in px (not points).
 */
ABI36_0_0RCT_EXPORT_METHOD(cropImage:(NSURLRequest *)imageRequest
                  cropData:(NSDictionary *)cropData
                  successCallback:(ABI36_0_0RCTResponseSenderBlock)successCallback
                  errorCallback:(ABI36_0_0RCTResponseErrorBlock)errorCallback)
{
  CGRect rect = {
    [ABI36_0_0RCTConvert CGPoint:cropData[@"offset"]],
    [ABI36_0_0RCTConvert CGSize:cropData[@"size"]]
  };

  [[_bridge moduleForName:@"ImageLoader"]
   loadImageWithURLRequest:imageRequest callback:^(NSError *error, UIImage *image) {
     if (error) {
       errorCallback(error);
       return;
     }

     // Crop image
     CGSize targetSize = rect.size;
     CGRect targetRect = {{-rect.origin.x, -rect.origin.y}, image.size};
     CGAffineTransform transform = ABI36_0_0RCTTransformFromTargetRect(image.size, targetRect);
     UIImage *croppedImage = ABI36_0_0RCTTransformImage(image, targetSize, image.scale, transform);

     // Scale image
     if (cropData[@"displaySize"]) {
       targetSize = [ABI36_0_0RCTConvert CGSize:cropData[@"displaySize"]]; // in pixels
       ABI36_0_0RCTResizeMode resizeMode = [ABI36_0_0RCTConvert ABI36_0_0RCTResizeMode:cropData[@"resizeMode"] ?: @"contain"];
       targetRect = ABI36_0_0RCTTargetRect(croppedImage.size, targetSize, 1, resizeMode);
       transform = ABI36_0_0RCTTransformFromTargetRect(croppedImage.size, targetRect);
       croppedImage = ABI36_0_0RCTTransformImage(croppedImage, targetSize, image.scale, transform);
     }

     // Store image
     [self->_bridge.imageStoreManager storeImage:croppedImage withBlock:^(NSString *croppedImageTag) {
       if (!croppedImageTag) {
         NSString *errorMessage = @"Error storing cropped image in ABI36_0_0RCTImageStoreManager";
         ABI36_0_0RCTLogWarn(@"%@", errorMessage);
         errorCallback(ABI36_0_0RCTErrorWithMessage(errorMessage));
         return;
       }
       successCallback(@[croppedImageTag]);
     }];
   }];
}

@end
