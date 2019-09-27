//
//  ABI35_0_0EXAR.m
//  Exponent
//
//  Created by Evan Bacon on 4/26/18.
//  Copyright © 2018 650 Industries. All rights reserved.
//

#import "ABI35_0_0EXAR.h"
#import "ABI35_0_0EXUnversioned.h"
#import "ABI35_0_0EXGLView.h"
#import <ReactABI35_0_0/ABI35_0_0RCTUIManager.h>
#import "ABI35_0_0EXGLARSessionManager.h"

@interface ABI35_0_0EXAR () <ABI35_0_0EXGLARSessionManagerDelegate>

@property (nonatomic, strong) id arSessionManager;

@end

@implementation ABI35_0_0EXAR

ABI35_0_0RCT_EXPORT_MODULE(ExponentAR);

- (dispatch_queue_t)methodQueue
{
  return self.bridge.uiManager.methodQueue;
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

- (void)didUpdateWithEvent:(NSString *)name payload:(NSDictionary *)payload
{
  if (self.bridge) {
    [self sendEventWithName:name body:payload];
  }
}

+ (NSDictionary *)serializeARVideoFormat:(ARVideoFormat *)videoFormat API_AVAILABLE(ios(11.3))
{
  return @{
           @"type": NSStringFromClass([videoFormat class]),
           @"imageResolution": @{
               @"width": @(videoFormat.imageResolution.width),
               @"height": @(videoFormat.imageResolution.height)
               },
           @"framesPerSecond": @(videoFormat.framesPerSecond)
           };
}

+ (NSMutableArray *)serializeARVideoFormats:(NSArray<ARVideoFormat *>*)videoFormats  API_AVAILABLE(ios(11.3))
{
  NSMutableArray *output = [NSMutableArray array];
  
  if (@available(iOS 11.3, *)) {
    for (ARVideoFormat *videoFormat in videoFormats) {
      [output addObject:[ABI35_0_0EXAR serializeARVideoFormat: videoFormat]];
    }
  }
  
  return output;
}

- (NSDictionary<NSString *, NSString *> *)constantsToExport
{
  NSDictionary *constants = @{
                              @"isSupported": @(NO),
                              @"frameDidUpdate": @"FRAME_DID_UPDATE",
                              @"anchorsDidUpdate": @"ANCHORS_DID_UPDATE",
                              @"cameraDidChangeTrackingState": @"CAMERA_DID_CHANGE_TRACKING_STATE",
                              @"didFailWithError": @"DID_FAIL_WITH_ERROR",
                              @"sessionWasInterrupted": @"SESSION_WAS_INTERRUPTED",
                              @"sessionInterruptionEnded": @"SESSION_INTERRUPTION_ENDED"
                              };
  
  NSMutableDictionary *output = [NSMutableDictionary dictionaryWithDictionary:constants];
  
  if (@available(iOS 11.0, *)) {
    [output addEntriesFromDictionary:@{
                                       @"isSupported": [ARSession class] ? @(YES) : @(NO),
                                       @"ARKitVersion": @"1.0",
                                       @"ARFaceTrackingConfiguration": @(NO),
                                       //[ARFaceTrackingConfiguration isSupported] ? @(YES) : @(NO),
                                       @"AROrientationTrackingConfiguration": [AROrientationTrackingConfiguration isSupported] ? @(YES) : @(NO),
                                       @"ARWorldTrackingConfiguration": [ARWorldTrackingConfiguration isSupported] ? @(YES) : @(NO),
                                       }];
  }
  
  if (@available(iOS 11.3, *)) {
    [output addEntriesFromDictionary:@{
                                       @"ARKitVersion": @"1.5",
//                                       @"FaceTrackingVideoFormats": [ABI35_0_0EXAR serializeARVideoFormats:[ARFaceTrackingConfiguration supportedVideoFormats]],
                                       @"WorldTrackingVideoFormats": [ABI35_0_0EXAR serializeARVideoFormats:[ARWorldTrackingConfiguration supportedVideoFormats]],
                                       @"OrientationTrackingVideoFormats": [ABI35_0_0EXAR serializeARVideoFormats:[AROrientationTrackingConfiguration supportedVideoFormats]],
                                       }];
  }
  
  return output;
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[
           @"FRAME_DID_UPDATE",
           @"DID_FAIL_WITH_ERROR",
           @"ANCHORS_DID_UPDATE",
           @"CAMERA_DID_CHANGE_TRACKING_STATE",
           @"SESSION_WAS_INTERRUPTED",
           @"SESSION_INTERRUPTION_ENDED"
           ];
}

ABI35_0_0RCT_REMAP_METHOD(startAsync,
                 startAsyncWithReactABI35_0_0Tag:(nonnull NSNumber *)tag
                 trackingConfiguration:(NSString *)trackingConfiguration
                 resolver:(ABI35_0_0RCTPromiseResolveBlock)resolve
                 rejecter:(ABI35_0_0RCTPromiseRejectBlock)reject)
{
  [self.bridge.uiManager addUIBlock:^(__unused ABI35_0_0RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
    UIView *view = viewRegistry[tag];
    if (![view isKindOfClass:[ABI35_0_0EXGLView class]]) {
      reject(@"E_GLVIEW_MANAGER_BAD_VIEW_TAG", nil, ABI35_0_0RCTErrorWithMessage(@"ABI35_0_0EXAR.startARSessionAsync: Expected an ABI35_0_0EXGLView"));
      return;
    }
    if (self->_arSessionManager) {
      [self->_arSessionManager stop];
      self->_arSessionManager = nil;
    }
    
    ABI35_0_0EXGLView *exglView = (ABI35_0_0EXGLView *)view;
    
    Class sessionManagerClass = NSClassFromString(@"ABI35_0_0EXGLARSessionManager");
    if (sessionManagerClass) {
      
      self->_arSessionManager = [[sessionManagerClass alloc] init];
      [self->_arSessionManager setDelegate:self];
      [exglView setArSessionManager:self->_arSessionManager];
      
      NSDictionary *response = [self->_arSessionManager startWithGLView:exglView trackingConfiguration: trackingConfiguration];
      if (response[@"error"]) {
        reject(@"ERR_ARKIT_FAILED_TO_INIT", response[@"error"], ABI35_0_0RCTErrorWithMessage(response[@"error"]));
      } else {
        resolve(response);
      }
    } else {
      NSString *response = @"ARKIT capabilities were not included with this build.";
      reject(@"ERR_ARKIT_FAILED_TO_INIT", response, ABI35_0_0RCTErrorWithMessage(response));
    }
  }];
}

ABI35_0_0RCT_REMAP_METHOD(stopAsync,
                 resolver:(ABI35_0_0RCTPromiseResolveBlock)resolve
                 rejecter:(ABI35_0_0RCTPromiseRejectBlock)reject)
{
  [self.bridge.uiManager addUIBlock:^(__unused ABI35_0_0RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
    if (self->_arSessionManager) {
      [self->_arSessionManager stop];
      self->_arSessionManager = nil;
    }
    resolve(nil);
  }];
}

ABI35_0_0RCT_EXPORT_METHOD(pause)
{
  [_arSessionManager pause];
}

ABI35_0_0RCT_EXPORT_METHOD(resume)
{
  [_arSessionManager resume];
}

ABI35_0_0RCT_EXPORT_METHOD(reset)
{
  [_arSessionManager reset];
}

ABI35_0_0RCT_REMAP_METHOD(setProvidesAudioData,
                 providesAudioData:(BOOL)providesAudioData)
{
  [_arSessionManager setProvidesAudioData:providesAudioData];
}

ABI35_0_0RCT_REMAP_BLOCKING_SYNCHRONOUS_METHOD(getProvidesAudioData, NSNumber *, getProvidesAudioData)
{
  return @([_arSessionManager providesAudioData]);
}

ABI35_0_0RCT_REMAP_METHOD(setLightEstimationEnabled,
                 lightEstimationEnabled:(BOOL)lightEstimationEnabled)
{
  [_arSessionManager setLightEstimationEnabled:lightEstimationEnabled];
}

ABI35_0_0RCT_REMAP_BLOCKING_SYNCHRONOUS_METHOD(getLightEstimationEnabled, NSNumber *, getLightEstimationEnabled)
{
  return @([_arSessionManager lightEstimationEnabled]);
}

ABI35_0_0RCT_REMAP_METHOD(setAutoFocusEnabled,
                 isAutoFocusEnabled:(BOOL)isAutoFocusEnabled)
{
  [_arSessionManager setAutoFocusEnabled:isAutoFocusEnabled];
}

ABI35_0_0RCT_REMAP_BLOCKING_SYNCHRONOUS_METHOD(getAutoFocusEnabled, NSNumber *, getAutoFocusEnabled)
{
  return @([_arSessionManager autoFocusEnabled]);
}

ABI35_0_0RCT_REMAP_BLOCKING_SYNCHRONOUS_METHOD(getPlaneDetection, NSString *, getPlaneDetection)
{
  NSArray *items = @[@"none", @"horizontal", @"vertical"];
  return [items objectAtIndex:[_arSessionManager planeDetection]];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
ABI35_0_0RCT_REMAP_METHOD(setPlaneDetection,
                 planeDetection:(ARPlaneDetection)planeDetection)
{
  [_arSessionManager setPlaneDetection:planeDetection];
}

ABI35_0_0RCT_REMAP_METHOD(setWorldAlignment,
                 worldAlignment:(ARWorldAlignment)worldAlignment)
{
  if (!_arSessionManager) {
    return;
  }
  [_arSessionManager setWorldAlignment:worldAlignment];
}

ABI35_0_0RCT_REMAP_BLOCKING_SYNCHRONOUS_METHOD(performHitTest,
                                      nullable NSDictionary *,
                                      performHitTestWithPoint:(CGPoint)point
                                      types:(ARHitTestResultType)types)
{
  if (!_arSessionManager) {
    return nil;
  }
  return [_arSessionManager performHitTest:point types:types];
}

#pragma clang diagnostic pop
#else

ABI35_0_0RCT_REMAP_BLOCKING_SYNCHRONOUS_METHOD(performHitTest,
                                      nullable NSDictionary *,
                                      performHitTestWithPoint:(CGPoint)point
                                      types:(NSString *)types)
{
  return nil;
}

ABI35_0_0RCT_REMAP_METHOD(setPlaneDetection,
                 planeDetection:(NSString *)planeDetection)
{
}

ABI35_0_0RCT_REMAP_METHOD(setWorldAlignment,
                 worldAlignment:(NSString *)worldAlignment)
{
}
#endif

ABI35_0_0RCT_REMAP_BLOCKING_SYNCHRONOUS_METHOD(getWorldAlignment, NSString *, getWorldAlignment)
{
  NSArray *items = @[@"gravity", @"gravityAndHeading", @"alignmentCamera"];
  return [items objectAtIndex:[_arSessionManager worldAlignment]];
}

ABI35_0_0RCT_REMAP_BLOCKING_SYNCHRONOUS_METHOD(getCurrentFrame,
                                      nullable NSDictionary *,
                                      getCurrentFrameWithAttributes:(NSDictionary *)attributes)
{
  return [_arSessionManager getCurrentFrameWithAttributes:attributes];
}

ABI35_0_0RCT_REMAP_BLOCKING_SYNCHRONOUS_METHOD(getARMatrices,
                                      nullable NSDictionary *,
                                      getARMatricesWithZNear:(nonnull NSNumber *)zNear
                                      zFar:(nonnull NSNumber *)zFar)
{
  if (!_arSessionManager) {
    return nil;
  }
  return [_arSessionManager arMatricesWithZNear:[zNear floatValue] zFar:[zFar floatValue]];
}

ABI35_0_0RCT_REMAP_BLOCKING_SYNCHRONOUS_METHOD(getVideoFormat, nullable NSDictionary *, getVideoFormat)
{
  if (!_arSessionManager) {
    return nil;
  }
  if (@available(iOS 11.3, *)) {
    ARVideoFormat *videoFormat = [_arSessionManager videoFormat];
    return [ABI35_0_0EXAR serializeARVideoFormat:videoFormat];
  }
  return nil;
}

ABI35_0_0RCT_REMAP_BLOCKING_SYNCHRONOUS_METHOD(getCameraTexture, NSNumber *, getCameraTexture)
{
  return @([_arSessionManager cameraTexture]);
}

ABI35_0_0RCT_REMAP_METHOD(setShouldAttemptRelocalization,
                 shouldAttemptRelocalization:(BOOL)shouldAttemptRelocalization)
{
  [_arSessionManager setShouldAttemptRelocalization:shouldAttemptRelocalization];
}

ABI35_0_0RCT_REMAP_METHOD(setWorldOriginAsync,
                 worldOrigin:(NSArray *)worldOrigin
                 resolver:(ABI35_0_0RCTPromiseResolveBlock)resolve
                 rejecter:(ABI35_0_0RCTPromiseRejectBlock)reject)
{
  if (worldOrigin.count != 16) {
    reject(@"E_AR_WORLD_ORIGIN", @"setWorldOriginAsync requires an array of 16 numbers.", nil);
    return;
  }
  vector_float4 v1 = { [worldOrigin[0] floatValue],[worldOrigin[1] floatValue],[worldOrigin[2] floatValue],[worldOrigin[3] floatValue] };
  vector_float4 v2 = { [worldOrigin[4] floatValue],[worldOrigin[5] floatValue],[worldOrigin[6] floatValue],[worldOrigin[7] floatValue] };
  vector_float4 v3 = { [worldOrigin[8] floatValue],[worldOrigin[9] floatValue],[worldOrigin[10] floatValue],[worldOrigin[11] floatValue] };
  vector_float4 v4 = { [worldOrigin[12] floatValue],[worldOrigin[13] floatValue],[worldOrigin[14] floatValue],[worldOrigin[15] floatValue] };
  matrix_float4x4 origin = { v1, v2, v3, v4 };
  [_arSessionManager setWorldOrigin:origin];
   resolve(@{});
}

ABI35_0_0RCT_REMAP_METHOD(setConfigurationAsync,
                 setConfigurationAsyncWithConfiguration:(NSString *)configuration
                 resolver:(ABI35_0_0RCTPromiseResolveBlock)resolve
                 rejecter:(ABI35_0_0RCTPromiseRejectBlock)reject)
{
  if (!_arSessionManager) {
    return;
  }
  NSError *error = [_arSessionManager startConfiguration:configuration];
  if (error) {
    reject(@"E_GLVIEW_MANAGER_BAD_AR_CONFIGURATION", @"ARKIT encountered an error: not a valid ARConfiguration.", error);
  } else {
    resolve(@{});
  }
}

ABI35_0_0RCT_REMAP_METHOD(setDetectionImagesAsync,
                 setDetectionImagesAsyncWithImages:(NSDictionary *)images
                 resolver:(ABI35_0_0RCTPromiseResolveBlock)resolve
                 rejecter:(ABI35_0_0RCTPromiseRejectBlock)reject)
{
  if (!_arSessionManager) {
    return;
  }
  if (@available(iOS 11.3, *)) {
    
    NSMutableArray *parsedImages = [NSMutableArray new];
    
    for (NSDictionary *staticAsset in [images allValues]) {
      NSMutableDictionary *asset = [staticAsset mutableCopy];
      
      NSURL *url = [NSURL URLWithString:asset[@"uri"]];
      NSString *path = [url.path stringByStandardizingPath];
      
      UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
      if (image == nil) {
        reject(@"E_CANNOT_OPEN", @"Could not open provided image", nil);
        return;
      }
      [asset setValue:image forKey:@"image"];
      [parsedImages addObject: asset];
    }
    [_arSessionManager setDetectionImages:parsedImages];
    resolve(@{});
  } else {
    reject(@"E_INVALID_VERSION", @"Detection images are only available on iOS 11.3+ devices", nil);
  }
}


@end
