/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI36_0_0RCTRootView.h"
#import "ABI36_0_0RCTRootViewDelegate.h"
#import "ABI36_0_0RCTRootViewInternal.h"

#import <objc/runtime.h>

#import "ABI36_0_0RCTAssert.h"
#import "ABI36_0_0RCTBridge.h"
#import "ABI36_0_0RCTBridge+Private.h"
#import "ABI36_0_0RCTEventDispatcher.h"
#import "ABI36_0_0RCTKeyCommands.h"
#import "ABI36_0_0RCTLog.h"
#import "ABI36_0_0RCTPerformanceLogger.h"
#import "ABI36_0_0RCTProfile.h"
#import "ABI36_0_0RCTRootContentView.h"
#import "ABI36_0_0RCTTouchHandler.h"
#import "ABI36_0_0RCTUIManager.h"
#import "ABI36_0_0RCTUIManagerUtils.h"
#import "ABI36_0_0RCTUtils.h"
#import "ABI36_0_0RCTView.h"
#import "ABI36_0_0UIView+React.h"

#if TARGET_OS_TV
#import "ABI36_0_0RCTTVRemoteHandler.h"
#import "ABI36_0_0RCTTVNavigationEventEmitter.h"
#endif

NSString *const ABI36_0_0RCTContentDidAppearNotification = @"ABI36_0_0RCTContentDidAppearNotification";

@interface ABI36_0_0RCTUIManager (ABI36_0_0RCTRootView)

- (NSNumber *)allocateRootTag;

@end

@implementation ABI36_0_0RCTRootView
{
  ABI36_0_0RCTBridge *_bridge;
  NSString *_moduleName;
  ABI36_0_0RCTRootContentView *_contentView;
  BOOL _passThroughTouches;
  CGSize _intrinsicContentSize;
}

- (instancetype)initWithBridge:(ABI36_0_0RCTBridge *)bridge
                    moduleName:(NSString *)moduleName
             initialProperties:(NSDictionary *)initialProperties
{
  ABI36_0_0RCTAssertMainQueue();
  ABI36_0_0RCTAssert(bridge, @"A bridge instance is required to create an ABI36_0_0RCTRootView");
  ABI36_0_0RCTAssert(moduleName, @"A moduleName is required to create an ABI36_0_0RCTRootView");

  ABI36_0_0RCT_PROFILE_BEGIN_EVENT(ABI36_0_0RCTProfileTagAlways, @"-[ABI36_0_0RCTRootView init]", nil);
  if (!bridge.isLoading) {
    [bridge.performanceLogger markStartForTag:ABI36_0_0RCTPLTTI];
  }

  if (self = [super initWithFrame:CGRectZero]) {
    self.backgroundColor = [UIColor whiteColor];

    _bridge = bridge;
    _moduleName = moduleName;
    _appProperties = [initialProperties copy];
    _loadingViewFadeDelay = 0.25;
    _loadingViewFadeDuration = 0.25;
    _sizeFlexibility = ABI36_0_0RCTRootViewSizeFlexibilityNone;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bridgeDidReload)
                                                 name:ABI36_0_0RCTJavaScriptWillStartLoadingNotification
                                               object:_bridge];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(javaScriptDidLoad:)
                                                 name:ABI36_0_0RCTJavaScriptDidLoadNotification
                                               object:_bridge];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideLoadingView)
                                                 name:ABI36_0_0RCTContentDidAppearNotification
                                               object:self];

#if TARGET_OS_TV
    self.tvRemoteHandler = [ABI36_0_0RCTTVRemoteHandler new];
    for (NSString *key in [self.tvRemoteHandler.tvRemoteGestureRecognizers allKeys]) {
      [self addGestureRecognizer:self.tvRemoteHandler.tvRemoteGestureRecognizers[key]];
    }
#endif

    [self showLoadingView];
  }

  ABI36_0_0RCT_PROFILE_END_EVENT(ABI36_0_0RCTProfileTagAlways, @"");

  return self;
}

- (instancetype)initWithBundleURL:(NSURL *)bundleURL
                       moduleName:(NSString *)moduleName
                initialProperties:(NSDictionary *)initialProperties
                    launchOptions:(NSDictionary *)launchOptions
{
  ABI36_0_0RCTBridge *bridge = [[ABI36_0_0RCTBridge alloc] initWithBundleURL:bundleURL
                                            moduleProvider:nil
                                             launchOptions:launchOptions];

  return [self initWithBridge:bridge moduleName:moduleName initialProperties:initialProperties];
}

ABI36_0_0RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
ABI36_0_0RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

#if TARGET_OS_TV
- (UIView *)preferredFocusedView
{
  if (self.ABI36_0_0ReactPreferredFocusedView) {
    return self.ABI36_0_0ReactPreferredFocusedView;
  }
  return [super preferredFocusedView];
}
#endif

#pragma mark - passThroughTouches

- (BOOL)passThroughTouches
{
  return _contentView.passThroughTouches;
}

- (void)setPassThroughTouches:(BOOL)passThroughTouches
{
  _passThroughTouches = passThroughTouches;
  _contentView.passThroughTouches = passThroughTouches;
}

#pragma mark - Layout

- (CGSize)sizeThatFits:(CGSize)size
{
  CGSize fitSize = _intrinsicContentSize;
  CGSize currentSize = self.bounds.size;

  // Following the current `size` and current `sizeFlexibility` policy.
  fitSize = CGSizeMake(
      _sizeFlexibility & ABI36_0_0RCTRootViewSizeFlexibilityWidth ? fitSize.width : currentSize.width,
      _sizeFlexibility & ABI36_0_0RCTRootViewSizeFlexibilityHeight ? fitSize.height : currentSize.height
    );

  // Following the given size constraints.
  fitSize = CGSizeMake(
      MIN(size.width, fitSize.width),
      MIN(size.height, fitSize.height)
    );

  return fitSize;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _contentView.frame = self.bounds;
  _loadingView.center = (CGPoint){
    CGRectGetMidX(self.bounds),
    CGRectGetMidY(self.bounds)
  };
}

- (UIViewController *)ABI36_0_0ReactViewController
{
  return _ABI36_0_0ReactViewController ?: [super ABI36_0_0ReactViewController];
}

- (BOOL)canBecomeFirstResponder
{
  return YES;
}

- (void)setLoadingView:(UIView *)loadingView
{
  _loadingView = loadingView;
  if (!_contentView.contentHasAppeared) {
    [self showLoadingView];
  }
}

- (void)showLoadingView
{
  if (_loadingView && !_contentView.contentHasAppeared) {
    _loadingView.hidden = NO;
    [self addSubview:_loadingView];
  }
}

- (void)hideLoadingView
{
  if (_loadingView.superview == self && _contentView.contentHasAppeared) {
    if (_loadingViewFadeDuration > 0) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_loadingViewFadeDelay * NSEC_PER_SEC)),
                     dispatch_get_main_queue(), ^{

                       [UIView transitionWithView:self
                                         duration:self->_loadingViewFadeDuration
                                          options:UIViewAnimationOptionTransitionCrossDissolve
                                       animations:^{
                                         self->_loadingView.hidden = YES;
                                       } completion:^(__unused BOOL finished) {
                                         [self->_loadingView removeFromSuperview];
                                       }];
                     });
    } else {
      _loadingView.hidden = YES;
      [_loadingView removeFromSuperview];
    }
  }
}

- (NSNumber *)ABI36_0_0ReactTag
{
  ABI36_0_0RCTAssertMainQueue();
  if (!super.ABI36_0_0ReactTag) {
    /**
     * Every root view that is created must have a unique ABI36_0_0React tag.
     * Numbering of these tags goes from 1, 11, 21, 31, etc
     *
     * NOTE: Since the bridge persists, the RootViews might be reused, so the
     * ABI36_0_0React tag must be re-assigned every time a new UIManager is created.
     */
    self.ABI36_0_0ReactTag = ABI36_0_0RCTAllocateRootViewTag();
  }
  return super.ABI36_0_0ReactTag;
}

- (void)bridgeDidReload
{
  ABI36_0_0RCTAssertMainQueue();
  // Clear the ABI36_0_0ReactTag so it can be re-assigned
  self.ABI36_0_0ReactTag = nil;
}

- (void)javaScriptDidLoad:(NSNotification *)notification
{
  ABI36_0_0RCTAssertMainQueue();

  // Use the (batched) bridge that's sent in the notification payload, so the
  // ABI36_0_0RCTRootContentView is scoped to the right bridge
  ABI36_0_0RCTBridge *bridge = notification.userInfo[@"bridge"];
  if (bridge != _contentView.bridge) {
    [self bundleFinishedLoading:bridge];
  }
}

- (void)bundleFinishedLoading:(ABI36_0_0RCTBridge *)bridge
{
  ABI36_0_0RCTAssert(bridge != nil, @"Bridge cannot be nil");
  if (!bridge.valid) {
    return;
  }

  [_contentView removeFromSuperview];
  _contentView = [[ABI36_0_0RCTRootContentView alloc] initWithFrame:self.bounds
                                                    bridge:bridge
                                                  ABI36_0_0ReactTag:self.ABI36_0_0ReactTag
                                            sizeFlexiblity:_sizeFlexibility];
  [self runApplication:bridge];

  _contentView.passThroughTouches = _passThroughTouches;
  [self insertSubview:_contentView atIndex:0];

  if (_sizeFlexibility == ABI36_0_0RCTRootViewSizeFlexibilityNone) {
    self.intrinsicContentSize = self.bounds.size;
  }
}

- (void)runApplication:(ABI36_0_0RCTBridge *)bridge
{
  NSString *moduleName = _moduleName ?: @"";
  NSDictionary *appParameters = @{
    @"rootTag": _contentView.ABI36_0_0ReactTag,
    @"initialProps": _appProperties ?: @{},
  };

  ABI36_0_0RCTLogInfo(@"Running application %@ (%@)", moduleName, appParameters);
  [bridge enqueueJSCall:@"AppRegistry"
                 method:@"runApplication"
                   args:@[moduleName, appParameters]
             completion:NULL];
}

- (void)setSizeFlexibility:(ABI36_0_0RCTRootViewSizeFlexibility)sizeFlexibility
{
  if (_sizeFlexibility == sizeFlexibility) {
    return;
  }

  _sizeFlexibility = sizeFlexibility;
  [self setNeedsLayout];
  _contentView.sizeFlexibility = _sizeFlexibility;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  // The root view itself should never receive touches
  UIView *hitView = [super hitTest:point withEvent:event];
  if (self.passThroughTouches && hitView == self) {
    return nil;
  }
  return hitView;
}

- (void)setAppProperties:(NSDictionary *)appProperties
{
  ABI36_0_0RCTAssertMainQueue();

  if ([_appProperties isEqualToDictionary:appProperties]) {
    return;
  }

  _appProperties = [appProperties copy];

  if (_contentView && _bridge.valid && !_bridge.loading) {
    [self runApplication:_bridge];
  }
}

- (void)setIntrinsicContentSize:(CGSize)intrinsicContentSize
{
  BOOL oldSizeHasAZeroDimension = _intrinsicContentSize.height == 0 || _intrinsicContentSize.width == 0;
  BOOL newSizeHasAZeroDimension = intrinsicContentSize.height == 0 || intrinsicContentSize.width == 0;
  BOOL bothSizesHaveAZeroDimension = oldSizeHasAZeroDimension && newSizeHasAZeroDimension;

  BOOL sizesAreEqual = CGSizeEqualToSize(_intrinsicContentSize, intrinsicContentSize);

  _intrinsicContentSize = intrinsicContentSize;

  // Don't notify the delegate if the content remains invisible or its size has not changed
  if (bothSizesHaveAZeroDimension || sizesAreEqual) {
    return;
  }
  
  [self invalidateIntrinsicContentSize];
  [self.superview setNeedsLayout];

  [_delegate rootViewDidChangeIntrinsicSize:self];
}

- (CGSize)intrinsicContentSize
{
  return _intrinsicContentSize;
}

- (void)contentViewInvalidated
{
  [_contentView removeFromSuperview];
  _contentView = nil;
  [self showLoadingView];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_contentView invalidate];
}

@end

@implementation ABI36_0_0RCTRootView (Deprecated)

- (CGSize)intrinsicSize
{
  ABI36_0_0RCTLogWarn(@"Calling deprecated `[-ABI36_0_0RCTRootView intrinsicSize]`.");
  return self.intrinsicContentSize;
}

- (void)cancelTouches
{
  ABI36_0_0RCTLogWarn(@"`-[ABI36_0_0RCTRootView cancelTouches]` is deprecated and will be deleted soon.");
  [[_contentView touchHandler] cancel];
}

@end
