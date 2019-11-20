/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

#import "ABI36_0_0RCTImagePickerManager.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <UIKit/UIKit.h>

#import <ABI36_0_0React/ABI36_0_0RCTConvert.h>
#import <ABI36_0_0React/ABI36_0_0RCTImageStoreManager.h>
#import <ABI36_0_0React/ABI36_0_0RCTRootView.h>
#import <ABI36_0_0React/ABI36_0_0RCTUtils.h>

@interface ABI36_0_0RCTImagePickerController : UIImagePickerController

@property (nonatomic, assign) BOOL unmirrorFrontFacingCamera;

@end

@implementation ABI36_0_0RCTImagePickerController

@end

@interface ABI36_0_0RCTImagePickerManager () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end

@implementation ABI36_0_0RCTImagePickerManager
{
  NSMutableArray<UIImagePickerController *> *_pickers;
  NSMutableArray<ABI36_0_0RCTResponseSenderBlock> *_pickerCallbacks;
  NSMutableArray<ABI36_0_0RCTResponseSenderBlock> *_pickerCancelCallbacks;
  NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *_pendingVideoInfo;
}

ABI36_0_0RCT_EXPORT_MODULE(ImagePickerIOS);

@synthesize bridge = _bridge;

- (id)init
{
  if (self = [super init]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cameraChanged:)
                                                 name:@"AVCaptureDeviceDidStartRunningNotification"
                                               object:nil];
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVCaptureDeviceDidStartRunningNotification" object:nil];
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

ABI36_0_0RCT_EXPORT_METHOD(canRecordVideos:(ABI36_0_0RCTResponseSenderBlock)callback)
{
  NSArray<NSString *> *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
  callback(@[@([availableMediaTypes containsObject:(NSString *)kUTTypeMovie])]);
}

ABI36_0_0RCT_EXPORT_METHOD(canUseCamera:(ABI36_0_0RCTResponseSenderBlock)callback)
{
  callback(@[@([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])]);
}

ABI36_0_0RCT_EXPORT_METHOD(openCameraDialog:(NSDictionary *)config
                  successCallback:(ABI36_0_0RCTResponseSenderBlock)callback
                  cancelCallback:(ABI36_0_0RCTResponseSenderBlock)cancelCallback)
{
  if (ABI36_0_0RCTRunningInAppExtension()) {
    cancelCallback(@[@"Camera access is unavailable in an app extension"]);
    return;
  }

  ABI36_0_0RCTImagePickerController *imagePicker = [ABI36_0_0RCTImagePickerController new];
  imagePicker.delegate = self;
  imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
  NSArray<NSString *> *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
  imagePicker.mediaTypes = availableMediaTypes;
  imagePicker.unmirrorFrontFacingCamera = [ABI36_0_0RCTConvert BOOL:config[@"unmirrorFrontFacingCamera"]];

  if ([ABI36_0_0RCTConvert BOOL:config[@"videoMode"]]) {
    imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
  }

  [self _presentPicker:imagePicker
       successCallback:callback
        cancelCallback:cancelCallback];
}

ABI36_0_0RCT_EXPORT_METHOD(openSelectDialog:(NSDictionary *)config
                  successCallback:(ABI36_0_0RCTResponseSenderBlock)callback
                  cancelCallback:(ABI36_0_0RCTResponseSenderBlock)cancelCallback)
{
  if (ABI36_0_0RCTRunningInAppExtension()) {
    cancelCallback(@[@"Image picker is currently unavailable in an app extension"]);
    return;
  }

  UIImagePickerController *imagePicker = [UIImagePickerController new];
  imagePicker.delegate = self;
  imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

  NSMutableArray<NSString *> *allowedTypes = [NSMutableArray new];
  if ([ABI36_0_0RCTConvert BOOL:config[@"showImages"]]) {
    [allowedTypes addObject:(NSString *)kUTTypeImage];
  }
  if ([ABI36_0_0RCTConvert BOOL:config[@"showVideos"]]) {
    [allowedTypes addObject:(NSString *)kUTTypeMovie];
  }

  imagePicker.mediaTypes = allowedTypes;

  [self _presentPicker:imagePicker
       successCallback:callback
        cancelCallback:cancelCallback];
}

// In iOS 13, the URLs provided when selecting videos from the library are only valid while the
// info object provided by the delegate is retained.
// This method provides a way to clear out all retained pending info objects.
ABI36_0_0RCT_EXPORT_METHOD(clearAllPendingVideos)
{
  [_pendingVideoInfo removeAllObjects];
  _pendingVideoInfo = [NSMutableDictionary new];
}

// In iOS 13, the URLs provided when selecting videos from the library are only valid while the
// info object provided by the delegate is retained.
// This method provides a way to release the info object for a particular file url when the application
// is done with it, for example after the video has been uploaded or copied locally.
ABI36_0_0RCT_EXPORT_METHOD(removePendingVideo:(NSString *)url)
{
  [_pendingVideoInfo removeObjectForKey:url];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info
{
  NSString *mediaType = info[UIImagePickerControllerMediaType];
  BOOL isMovie = [mediaType isEqualToString:(NSString *)kUTTypeMovie];
  NSString *key = isMovie ? UIImagePickerControllerMediaURL : UIImagePickerControllerReferenceURL;
  NSURL *imageURL = info[key];
  UIImage *image = info[UIImagePickerControllerOriginalImage];
  NSNumber *width = 0;
  NSNumber *height = 0;
  if (image) {
    height = @(image.size.height);
    width = @(image.size.width);
  }
  if (imageURL) {
    NSString *imageURLString = imageURL.absoluteString;
    // In iOS 13, video URLs are only valid while info dictionary is retained
    if (@available(iOS 13.0, *)) {
      if (isMovie) {
        _pendingVideoInfo[imageURLString] = info;
      }
    }

    [self _dismissPicker:picker args:@[imageURLString, ABI36_0_0RCTNullIfNil(height), ABI36_0_0RCTNullIfNil(width)]];
    return;
  }

  // This is a newly taken image, and doesn't have a URL yet.
  // We need to save it to the image store first.
  UIImage *originalImage = info[UIImagePickerControllerOriginalImage];

  // WARNING: Using ImageStoreManager may cause a memory leak because the
  // image isn't automatically removed from store once we're done using it.
  [_bridge.imageStoreManager storeImage:originalImage withBlock:^(NSString *tempImageTag) {
    [self _dismissPicker:picker args:tempImageTag ? @[tempImageTag, ABI36_0_0RCTNullIfNil(height), ABI36_0_0RCTNullIfNil(width)] : nil];
  }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  [self _dismissPicker:picker args:nil];
}

- (void)_presentPicker:(UIImagePickerController *)imagePicker
       successCallback:(ABI36_0_0RCTResponseSenderBlock)callback
        cancelCallback:(ABI36_0_0RCTResponseSenderBlock)cancelCallback
{
  if (!_pickers) {
    _pickers = [NSMutableArray new];
    _pickerCallbacks = [NSMutableArray new];
    _pickerCancelCallbacks = [NSMutableArray new];
    _pendingVideoInfo = [NSMutableDictionary new];
  }

  [_pickers addObject:imagePicker];
  [_pickerCallbacks addObject:callback];
  [_pickerCancelCallbacks addObject:cancelCallback];

  UIViewController *rootViewController = ABI36_0_0RCTPresentedViewController();
  [rootViewController presentViewController:imagePicker animated:YES completion:nil];
}

- (void)_dismissPicker:(UIImagePickerController *)picker args:(NSArray *)args
{
  NSUInteger index = [_pickers indexOfObject:picker];
  if (index == NSNotFound) {
    // This happens if the user selects multiple items in succession.
    return;
  }

  ABI36_0_0RCTResponseSenderBlock successCallback = _pickerCallbacks[index];
  ABI36_0_0RCTResponseSenderBlock cancelCallback = _pickerCancelCallbacks[index];

  [_pickers removeObjectAtIndex:index];
  [_pickerCallbacks removeObjectAtIndex:index];
  [_pickerCancelCallbacks removeObjectAtIndex:index];

  UIViewController *rootViewController = ABI36_0_0RCTPresentedViewController();
  [rootViewController dismissViewControllerAnimated:YES completion:nil];

  if (args) {
    successCallback(args);
  } else {
    cancelCallback(@[]);
  }
}

- (void)cameraChanged:(NSNotification *)notification
{
  for (UIImagePickerController *picker in _pickers) {
    if ([picker isKindOfClass:[ABI36_0_0RCTImagePickerController class]]
      && ((ABI36_0_0RCTImagePickerController *)picker).unmirrorFrontFacingCamera
      && picker.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
      picker.cameraViewTransform = CGAffineTransformScale(CGAffineTransformIdentity, -1, 1);
    } else {
      picker.cameraViewTransform = CGAffineTransformIdentity;
    }
  }
}

@end
