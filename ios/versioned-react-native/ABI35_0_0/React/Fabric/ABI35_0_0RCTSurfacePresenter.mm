/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI35_0_0RCTSurfacePresenter.h"

#import <objc/runtime.h>
#import <mutex>
#import <ABI35_0_0jsi/ABI35_0_0jsi.h>
#import <cxxReactABI35_0_0/ABI35_0_0MessageQueueThread.h>

#import <ReactABI35_0_0/ABI35_0_0RCTAssert.h>
#import <ReactABI35_0_0/ABI35_0_0RCTBridge+Private.h>
#import <ReactABI35_0_0/ABI35_0_0RCTComponentViewRegistry.h>
#import <ReactABI35_0_0/ABI35_0_0RCTFabricSurface.h>
#import <ReactABI35_0_0/ABI35_0_0RCTImageLoader.h>
#import <ReactABI35_0_0/ABI35_0_0RCTMountingManager.h>
#import <ReactABI35_0_0/ABI35_0_0RCTMountingManagerDelegate.h>
#import <ReactABI35_0_0/ABI35_0_0RCTScheduler.h>
#import <ReactABI35_0_0/ABI35_0_0RCTSurfaceRegistry.h>
#import <ReactABI35_0_0/ABI35_0_0RCTSurfaceView.h>
#import <ReactABI35_0_0/ABI35_0_0RCTSurfaceView+Internal.h>
#import <ReactABI35_0_0/ABI35_0_0RCTUtils.h>
#import <ReactABI35_0_0/core/LayoutContext.h>
#import <ReactABI35_0_0/core/LayoutConstraints.h>
#import <ReactABI35_0_0/components/root/RootShadowNode.h>
#import <ReactABI35_0_0/imagemanager/ImageManager.h>
#import <ReactABI35_0_0/uimanager/ContextContainer.h>

#import "ABI35_0_0MainRunLoopEventBeat.h"
#import "ABI35_0_0RuntimeEventBeat.h"
#import "ABI35_0_0RCTConversions.h"

using namespace facebook::ReactABI35_0_0;

@interface ABI35_0_0RCTBridge ()
- (std::shared_ptr<facebook::ReactABI35_0_0::MessageQueueThread>)jsMessageThread;
@end

@interface ABI35_0_0RCTSurfacePresenter () <ABI35_0_0RCTSchedulerDelegate, ABI35_0_0RCTMountingManagerDelegate>
@end

@implementation ABI35_0_0RCTSurfacePresenter {
  std::mutex _schedulerMutex;
  std::mutex _contextContainerMutex;
  ABI35_0_0RCTScheduler *_Nullable _scheduler; // Thread-safe. Mutation of the instance variable is protected by `_schedulerMutex`.
  ABI35_0_0RCTMountingManager *_mountingManager; // Thread-safe.
  ABI35_0_0RCTSurfaceRegistry *_surfaceRegistry;  // Thread-safe.
  ABI35_0_0RCTBridge *_bridge; // Unsafe. We are moving away from Bridge.
  ABI35_0_0RCTBridge *_batchedBridge;
  std::shared_ptr<const ReactABI35_0_0NativeConfig> _ReactABI35_0_0NativeConfig;
}

- (instancetype)initWithBridge:(ABI35_0_0RCTBridge *)bridge config:(std::shared_ptr<const ReactABI35_0_0NativeConfig>)config
{
  if (self = [super init]) {
    _bridge = bridge;
    _batchedBridge = [_bridge batchedBridge] ?: _bridge;

    _surfaceRegistry = [[ABI35_0_0RCTSurfaceRegistry alloc] init];

    _mountingManager = [[ABI35_0_0RCTMountingManager alloc] init];
    _mountingManager.delegate = self;

    if (config != nullptr) {
      _ReactABI35_0_0NativeConfig = config;
    } else {
      _ReactABI35_0_0NativeConfig = std::make_shared<const EmptyReactABI35_0_0NativeConfig>();
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBridgeWillReloadNotification:)
                                                 name:ABI35_0_0RCTBridgeWillReloadNotification
                                               object:_bridge];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleJavaScriptDidLoadNotification:)
                                                 name:ABI35_0_0RCTJavaScriptDidLoadNotification
                                               object:_bridge];
  }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (ABI35_0_0RCTComponentViewFactory *)componentViewFactory
{
  return _mountingManager.componentViewRegistry.componentViewFactory;
}

#pragma mark - Internal Surface-dedicated Interface

- (void)registerSurface:(ABI35_0_0RCTFabricSurface *)surface
{
  [_surfaceRegistry registerSurface:surface];
}

- (void)startSurface:(ABI35_0_0RCTFabricSurface *)surface
{
  [self _startSurface:surface];
}

- (void)unregisterSurface:(ABI35_0_0RCTFabricSurface *)surface
{
  [self _stopSurface:surface];
  [_surfaceRegistry unregisterSurface:surface];
}

- (void)setProps:(NSDictionary *)props
         surface:(ABI35_0_0RCTFabricSurface *)surface
{
  // This implementation is suboptimal indeed but still better than nothing for now.
  [self _stopSurface:surface];
  [self _startSurface:surface];
}

- (ABI35_0_0RCTFabricSurface *)surfaceForRootTag:(ReactABI35_0_0Tag)rootTag
{
  return [_surfaceRegistry surfaceForRootTag:rootTag];
}

- (CGSize)sizeThatFitsMinimumSize:(CGSize)minimumSize
                      maximumSize:(CGSize)maximumSize
                          surface:(ABI35_0_0RCTFabricSurface *)surface
{
  LayoutContext layoutContext = {
    .pointScaleFactor = ABI35_0_0RCTScreenScale()
  };

  LayoutConstraints layoutConstraints = {
    .minimumSize = ABI35_0_0RCTSizeFromCGSize(minimumSize),
    .maximumSize = ABI35_0_0RCTSizeFromCGSize(maximumSize)
  };

  return [self._scheduler measureSurfaceWithLayoutConstraints:layoutConstraints
                                                layoutContext:layoutContext
                                                    surfaceId:surface.rootTag];
}

- (void)setMinimumSize:(CGSize)minimumSize
           maximumSize:(CGSize)maximumSize
               surface:(ABI35_0_0RCTFabricSurface *)surface
{
  LayoutContext layoutContext = {
    .pointScaleFactor = ABI35_0_0RCTScreenScale()
  };

  LayoutConstraints layoutConstraints = {
    .minimumSize = ABI35_0_0RCTSizeFromCGSize(minimumSize),
    .maximumSize = ABI35_0_0RCTSizeFromCGSize(maximumSize)
  };

  [self._scheduler constraintSurfaceLayoutWithLayoutConstraints:layoutConstraints
                                                  layoutContext:layoutContext
                                                      surfaceId:surface.rootTag];
}

#pragma mark - Private

- (ABI35_0_0RCTScheduler *)_scheduler
{
  std::lock_guard<std::mutex> lock(_schedulerMutex);

  if (_scheduler) {
    return _scheduler;
  }

  _scheduler = [[ABI35_0_0RCTScheduler alloc] initWithContextContainer:self.contextContainer];
  _scheduler.delegate = self;

  return _scheduler;
}

@synthesize contextContainer = _contextContainer;

- (SharedContextContainer)contextContainer
{
  std::lock_guard<std::mutex> lock(_contextContainerMutex);

  if (_contextContainer) {
    return _contextContainer;
  }

  _contextContainer = std::make_shared<ContextContainer>();

  _contextContainer->registerInstance(_ReactABI35_0_0NativeConfig, "ReactABI35_0_0NativeConfig");

  auto messageQueueThread = _batchedBridge.jsMessageThread;
  auto runtime = (facebook::jsi::Runtime *)((ABI35_0_0RCTCxxBridge *)_batchedBridge).runtime;

  RuntimeExecutor runtimeExecutor =
    [runtime, messageQueueThread](std::function<void(facebook::jsi::Runtime &runtime)> &&callback) {
      messageQueueThread->runOnQueue([runtime, callback = std::move(callback)]() {
        callback(*runtime);
      });
    };

  EventBeatFactory synchronousBeatFactory = [runtimeExecutor]() {
    return std::make_unique<MainRunLoopEventBeat>(runtimeExecutor);
  };

  EventBeatFactory asynchronousBeatFactory = [runtimeExecutor]() {
    return std::make_unique<RuntimeEventBeat>(runtimeExecutor);
  };

  _contextContainer->registerInstance<EventBeatFactory>(synchronousBeatFactory, "synchronous");
  _contextContainer->registerInstance<EventBeatFactory>(asynchronousBeatFactory, "asynchronous");

  _contextContainer->registerInstance(runtimeExecutor, "runtime-executor");

  _contextContainer->registerInstance(std::make_shared<ImageManager>((__bridge void *)[_bridge imageLoader]), "ImageManager");
  return _contextContainer;
}

- (void)_startSurface:(ABI35_0_0RCTFabricSurface *)surface
{
  [_mountingManager.componentViewRegistry dequeueComponentViewWithComponentHandle:RootShadowNode::Handle()
                                                                              tag:surface.rootTag];

  LayoutContext layoutContext = {
    .pointScaleFactor = ABI35_0_0RCTScreenScale()
  };

  LayoutConstraints layoutConstraints = {
    .minimumSize = ABI35_0_0RCTSizeFromCGSize(surface.minimumSize),
    .maximumSize = ABI35_0_0RCTSizeFromCGSize(surface.maximumSize)
  };

  [self._scheduler startSurfaceWithSurfaceId:surface.rootTag
                                  moduleName:surface.moduleName
                                initailProps:surface.properties
                           layoutConstraints:layoutConstraints
                               layoutContext:layoutContext];
}

- (void)_stopSurface:(ABI35_0_0RCTFabricSurface *)surface
{
  [self._scheduler stopSurfaceWithSurfaceId:surface.rootTag];

  UIView<ABI35_0_0RCTComponentViewProtocol> *rootView =
    [_mountingManager.componentViewRegistry componentViewByTag:surface.rootTag];
  [_mountingManager.componentViewRegistry enqueueComponentViewWithComponentHandle:RootShadowNode::Handle()
                                                                              tag:surface.rootTag
                                                                    componentView:rootView];

  [surface _unsetStage:(ABI35_0_0RCTSurfaceStagePrepared | ABI35_0_0RCTSurfaceStageMounted)];
}

- (void)_startAllSurfaces
{
  for (ABI35_0_0RCTFabricSurface *surface in _surfaceRegistry.enumerator) {
    [self _startSurface:surface];
  }
}

- (void)_stopAllSurfaces
{
  for (ABI35_0_0RCTFabricSurface *surface in _surfaceRegistry.enumerator) {
    [self _stopSurface:surface];
  }
}

#pragma mark - ABI35_0_0RCTSchedulerDelegate

- (void)schedulerDidFinishTransaction:(facebook::ReactABI35_0_0::ShadowViewMutationList)mutations
                                        rootTag:(ReactABI35_0_0Tag)rootTag
{
  ABI35_0_0RCTFabricSurface *surface = [_surfaceRegistry surfaceForRootTag:rootTag];

  [surface _setStage:ABI35_0_0RCTSurfaceStagePrepared];

  [_mountingManager performTransactionWithMutations:mutations
                                            rootTag:rootTag];
}

- (void)schedulerOptimisticallyCreateComponentViewWithComponentHandle:(ComponentHandle)componentHandle
{
  [_mountingManager optimisticallyCreateComponentViewWithComponentHandle:componentHandle];
}

#pragma mark - ABI35_0_0RCTMountingManagerDelegate

- (void)mountingManager:(ABI35_0_0RCTMountingManager *)mountingManager willMountComponentsWithRootTag:(ReactABI35_0_0Tag)rootTag
{
  ABI35_0_0RCTAssertMainQueue();

  // Does nothing.
}

- (void)mountingManager:(ABI35_0_0RCTMountingManager *)mountingManager didMountComponentsWithRootTag:(ReactABI35_0_0Tag)rootTag
{
  ABI35_0_0RCTAssertMainQueue();

  ABI35_0_0RCTFabricSurface *surface = [_surfaceRegistry surfaceForRootTag:rootTag];
  ABI35_0_0RCTSurfaceStage stage = surface.stage;
  if (stage & ABI35_0_0RCTSurfaceStagePrepared) {
    // We have to progress the stage only if the preparing phase is done.
    if ([surface _setStage:ABI35_0_0RCTSurfaceStageMounted]) {
      UIView *rootComponentView = [_mountingManager.componentViewRegistry componentViewByTag:rootTag];
      surface.view.rootView = (ABI35_0_0RCTSurfaceRootView *)rootComponentView;
    }
  }
}

#pragma mark - Bridge events

- (void)handleBridgeWillReloadNotification:(NSNotification *)notification
{
  {
    std::lock_guard<std::mutex> lock(_schedulerMutex);
    if (!_scheduler) {
      // Seems we are already in the realoding process.
      return;
    }
  }

  [self _stopAllSurfaces];

  {
    std::lock_guard<std::mutex> lock(_schedulerMutex);
    _scheduler = nil;
    _contextContainer = nil;
  }
}

- (void)handleJavaScriptDidLoadNotification:(NSNotification *)notification
{
  ABI35_0_0RCTBridge *bridge = notification.userInfo[@"bridge"];
  if (bridge != _batchedBridge) {
    _batchedBridge = bridge;

    [self _startAllSurfaces];
  }
}

@end

@implementation ABI35_0_0RCTSurfacePresenter (Deprecated)

- (ABI35_0_0RCTBridge *)bridge_DO_NOT_USE
{
  return _bridge;
}

@end

@implementation ABI35_0_0RCTBridge (Deprecated)

- (void)setSurfacePresenter:(ABI35_0_0RCTSurfacePresenter *)surfacePresenter
{
  objc_setAssociatedObject(self, @selector(surfacePresenter), surfacePresenter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ABI35_0_0RCTSurfacePresenter *)surfacePresenter
{
  return objc_getAssociatedObject(self, @selector(surfacePresenter));
}

@end
