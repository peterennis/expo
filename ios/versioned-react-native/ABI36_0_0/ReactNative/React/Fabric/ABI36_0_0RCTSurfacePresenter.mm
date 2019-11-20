/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI36_0_0RCTSurfacePresenter.h"

#import <ABI36_0_0cxxreact/ABI36_0_0MessageQueueThread.h>
#import <ABI36_0_0jsi/ABI36_0_0jsi.h>
#import <objc/runtime.h>
#import <mutex>

#import <ABI36_0_0React/ABI36_0_0RCTAssert.h>
#import <ABI36_0_0React/ABI36_0_0RCTBridge+Private.h>
#import <ABI36_0_0React/ABI36_0_0RCTComponentViewFactory.h>
#import <ABI36_0_0React/ABI36_0_0RCTComponentViewRegistry.h>
#import <ABI36_0_0React/ABI36_0_0RCTFabricSurface.h>
#import <ABI36_0_0React/ABI36_0_0RCTFollyConvert.h>
#import <ABI36_0_0React/ABI36_0_0RCTImageLoader.h>
#import <ABI36_0_0React/ABI36_0_0RCTMountingManager.h>
#import <ABI36_0_0React/ABI36_0_0RCTMountingManagerDelegate.h>
#import <ABI36_0_0React/ABI36_0_0RCTScheduler.h>
#import <ABI36_0_0React/ABI36_0_0RCTSurfaceRegistry.h>
#import <ABI36_0_0React/ABI36_0_0RCTSurfaceView+Internal.h>
#import <ABI36_0_0React/ABI36_0_0RCTSurfaceView.h>
#import <ABI36_0_0React/ABI36_0_0RCTUtils.h>

#import <ABI36_0_0React/components/root/RootShadowNode.h>
#import <ABI36_0_0React/core/LayoutConstraints.h>
#import <ABI36_0_0React/core/LayoutContext.h>
#import <ABI36_0_0React/uimanager/ComponentDescriptorFactory.h>
#import <ABI36_0_0React/uimanager/SchedulerToolbox.h>
#import <ABI36_0_0React/utils/ContextContainer.h>
#import <ABI36_0_0React/utils/ManagedObjectWrapper.h>

#import "ABI36_0_0MainRunLoopEventBeat.h"
#import "ABI36_0_0RCTConversions.h"
#import "ABI36_0_0RuntimeEventBeat.h"

using namespace ABI36_0_0facebook::ABI36_0_0React;

@interface ABI36_0_0RCTBridge ()
- (std::shared_ptr<ABI36_0_0facebook::ABI36_0_0React::MessageQueueThread>)jsMessageThread;
- (void)invokeAsync:(std::function<void()> &&)func;
@end

@interface ABI36_0_0RCTSurfacePresenter () <ABI36_0_0RCTSchedulerDelegate, ABI36_0_0RCTMountingManagerDelegate>
@end

@implementation ABI36_0_0RCTSurfacePresenter {
  std::mutex _schedulerMutex;
  std::mutex _contextContainerMutex;
  ABI36_0_0RCTScheduler
      *_Nullable _scheduler; // Thread-safe. Mutation of the instance variable is protected by `_schedulerMutex`.
  ABI36_0_0RCTMountingManager *_mountingManager; // Thread-safe.
  ABI36_0_0RCTSurfaceRegistry *_surfaceRegistry; // Thread-safe.
  ABI36_0_0RCTBridge *_bridge; // Unsafe. We are moving away from Bridge.
  ABI36_0_0RCTBridge *_batchedBridge;
  std::shared_ptr<const ABI36_0_0ReactNativeConfig> _ABI36_0_0ReactNativeConfig;
  better::shared_mutex _observerListMutex;
  NSMutableArray<id<ABI36_0_0RCTSurfacePresenterObserver>> *_observers;
  ABI36_0_0RCTImageLoader *_imageLoader;
  RuntimeExecutor _runtimeExecutor;
}

- (instancetype)initWithBridge:(ABI36_0_0RCTBridge *)bridge
                        config:(std::shared_ptr<const ABI36_0_0ReactNativeConfig>)config
                   imageLoader:(ABI36_0_0RCTImageLoader *)imageLoader
               runtimeExecutor:(RuntimeExecutor)runtimeExecutor
{
  if (self = [super init]) {
    _imageLoader = imageLoader;
    _runtimeExecutor = runtimeExecutor;
    _bridge = bridge;
    _batchedBridge = [_bridge batchedBridge] ?: _bridge;
    [_batchedBridge setSurfacePresenter:self];

    _surfaceRegistry = [[ABI36_0_0RCTSurfaceRegistry alloc] init];

    _mountingManager = [[ABI36_0_0RCTMountingManager alloc] init];
    _mountingManager.delegate = self;

    if (config != nullptr) {
      _ABI36_0_0ReactNativeConfig = config;
    } else {
      _ABI36_0_0ReactNativeConfig = std::make_shared<const EmptyABI36_0_0ReactNativeConfig>();
    }

    _observers = [NSMutableArray array];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBridgeWillReloadNotification:)
                                                 name:ABI36_0_0RCTBridgeWillReloadNotification
                                               object:_bridge];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleJavaScriptDidLoadNotification:)
                                                 name:ABI36_0_0RCTJavaScriptDidLoadNotification
                                               object:_bridge];
  }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (ABI36_0_0RCTComponentViewFactory *)componentViewFactory
{
  return _mountingManager.componentViewRegistry.componentViewFactory;
}

#pragma mark - Internal Surface-dedicated Interface

- (void)registerSurface:(ABI36_0_0RCTFabricSurface *)surface
{
  [_surfaceRegistry registerSurface:surface];
}

- (void)startSurface:(ABI36_0_0RCTFabricSurface *)surface
{
  [self _startSurface:surface];
}

- (void)unregisterSurface:(ABI36_0_0RCTFabricSurface *)surface
{
  [self _stopSurface:surface];
  [_surfaceRegistry unregisterSurface:surface];
}

- (void)setProps:(NSDictionary *)props surface:(ABI36_0_0RCTFabricSurface *)surface
{
  // This implementation is suboptimal indeed but still better than nothing for now.
  [self _stopSurface:surface];
  [self _startSurface:surface];
}

- (ABI36_0_0RCTFabricSurface *)surfaceForRootTag:(ABI36_0_0ReactTag)rootTag
{
  return [_surfaceRegistry surfaceForRootTag:rootTag];
}

- (CGSize)sizeThatFitsMinimumSize:(CGSize)minimumSize
                      maximumSize:(CGSize)maximumSize
                          surface:(ABI36_0_0RCTFabricSurface *)surface
{
  LayoutContext layoutContext = {.pointScaleFactor = ABI36_0_0RCTScreenScale()};

  LayoutConstraints layoutConstraints = {.minimumSize = ABI36_0_0RCTSizeFromCGSize(minimumSize),
                                         .maximumSize = ABI36_0_0RCTSizeFromCGSize(maximumSize)};

  return [self._scheduler measureSurfaceWithLayoutConstraints:layoutConstraints
                                                layoutContext:layoutContext
                                                    surfaceId:surface.rootTag];
}

- (void)setMinimumSize:(CGSize)minimumSize maximumSize:(CGSize)maximumSize surface:(ABI36_0_0RCTFabricSurface *)surface
{
  LayoutContext layoutContext = {.pointScaleFactor = ABI36_0_0RCTScreenScale()};

  LayoutConstraints layoutConstraints = {.minimumSize = ABI36_0_0RCTSizeFromCGSize(minimumSize),
                                         .maximumSize = ABI36_0_0RCTSizeFromCGSize(maximumSize)};

  [self._scheduler constraintSurfaceLayoutWithLayoutConstraints:layoutConstraints
                                                  layoutContext:layoutContext
                                                      surfaceId:surface.rootTag];
}

- (BOOL)synchronouslyUpdateViewOnUIThread:(NSNumber *)ABI36_0_0ReactTag props:(NSDictionary *)props
{
  ABI36_0_0ReactTag tag = [ABI36_0_0ReactTag integerValue];
  UIView<ABI36_0_0RCTComponentViewProtocol> *componentView = [_mountingManager.componentViewRegistry componentViewByTag:tag];
  if (componentView == nil) {
    return NO; // This view probably isn't managed by Fabric
  }
  ComponentHandle handle = [[componentView class] componentDescriptorProvider].handle;
  const ABI36_0_0facebook::ABI36_0_0React::ComponentDescriptor &componentDescriptor = [self._scheduler getComponentDescriptor:handle];
  [self->_mountingManager synchronouslyUpdateViewOnUIThread:tag
                                               changedProps:props
                                        componentDescriptor:componentDescriptor];
  return YES;
}

#pragma mark - Private

- (ABI36_0_0RCTScheduler *)_scheduler
{
  std::lock_guard<std::mutex> lock(_schedulerMutex);

  if (_scheduler) {
    return _scheduler;
  }

  auto componentRegistryFactory = [factory = wrapManagedObject(self.componentViewFactory)](
                                      EventDispatcher::Shared const &eventDispatcher,
                                      ContextContainer::Shared const &contextContainer) {
    return [(ABI36_0_0RCTComponentViewFactory *)unwrapManagedObject(factory)
        createComponentDescriptorRegistryWithParameters:{eventDispatcher, contextContainer}];
  };

  auto runtimeExecutor = [self getRuntimeExecutor];

  auto toolbox = SchedulerToolbox{};
  toolbox.contextContainer = self.contextContainer;
  toolbox.componentRegistryFactory = componentRegistryFactory;
  toolbox.runtimeExecutor = runtimeExecutor;

  toolbox.synchronousEventBeatFactory = [runtimeExecutor]() {
    return std::make_unique<MainRunLoopEventBeat>(runtimeExecutor);
  };

  toolbox.asynchronousEventBeatFactory = [runtimeExecutor]() {
    return std::make_unique<RuntimeEventBeat>(runtimeExecutor);
  };

  _scheduler = [[ABI36_0_0RCTScheduler alloc] initWithToolbox:toolbox];
  _scheduler.delegate = self;

  return _scheduler;
}

@synthesize contextContainer = _contextContainer;

- (RuntimeExecutor)getRuntimeExecutor
{
  if (_runtimeExecutor) {
    return _runtimeExecutor;
  }

  auto messageQueueThread = _batchedBridge.jsMessageThread;
  if (messageQueueThread) {
    // Make sure initializeBridge completed
    messageQueueThread->runOnQueueSync([] {});
  }

  auto runtime = (ABI36_0_0facebook::jsi::Runtime *)((ABI36_0_0RCTCxxBridge *)_batchedBridge).runtime;

  RuntimeExecutor runtimeExecutor = [self, runtime](std::function<void(ABI36_0_0facebook::jsi::Runtime & runtime)> &&callback) {
    // For now, ask the bridge to queue the callback asynchronously to ensure that
    // it's not invoked too early, e.g. before the bridge is fully ready.
    // Revisit this after Fabric/TurboModule is fully rolled out.
    [((ABI36_0_0RCTCxxBridge *)_batchedBridge) invokeAsync:[runtime, callback = std::move(callback)]() { callback(*runtime); }];
  };

  return runtimeExecutor;
}

- (ContextContainer::Shared)contextContainer
{
  std::lock_guard<std::mutex> lock(_contextContainerMutex);

  if (_contextContainer) {
    return _contextContainer;
  }

  _contextContainer = std::make_shared<ContextContainer>();
  // Please do not add stuff here; `SurfacePresenter` must not alter `ContextContainer`.
  // Those two pieces eventually should be moved out there:
  // * `ABI36_0_0RCTImageLoader` should be moved to `ABI36_0_0RCTImageComponentView`.
  // * `ABI36_0_0ReactNativeConfig` should be set by outside product code.
  _contextContainer->insert("ABI36_0_0ReactNativeConfig", _ABI36_0_0ReactNativeConfig);
  // TODO T47869586 petetheheat: Delete else case when TM rollout 100%
  if (_imageLoader) {
    _contextContainer->insert("ABI36_0_0RCTImageLoader", wrapManagedObject(_imageLoader));
  } else {
    _contextContainer->insert("ABI36_0_0RCTImageLoader", wrapManagedObject([_bridge moduleForClass:[ABI36_0_0RCTImageLoader class]]));
  }

  return _contextContainer;
}

- (void)_startSurface:(ABI36_0_0RCTFabricSurface *)surface
{
  ABI36_0_0RCTMountingManager *mountingManager = _mountingManager;
  ABI36_0_0RCTExecuteOnMainQueue(^{
    [mountingManager.componentViewRegistry dequeueComponentViewWithComponentHandle:RootShadowNode::Handle()
                                                                               tag:surface.rootTag];
  });

  LayoutContext layoutContext = {.pointScaleFactor = ABI36_0_0RCTScreenScale()};

  LayoutConstraints layoutConstraints = {.minimumSize = ABI36_0_0RCTSizeFromCGSize(surface.minimumSize),
                                         .maximumSize = ABI36_0_0RCTSizeFromCGSize(surface.maximumSize)};

  [self._scheduler startSurfaceWithSurfaceId:surface.rootTag
                                  moduleName:surface.moduleName
                                initialProps:surface.properties
                           layoutConstraints:layoutConstraints
                               layoutContext:layoutContext];
}

- (void)_stopSurface:(ABI36_0_0RCTFabricSurface *)surface
{
  [self._scheduler stopSurfaceWithSurfaceId:surface.rootTag];

  ABI36_0_0RCTMountingManager *mountingManager = _mountingManager;
  ABI36_0_0RCTExecuteOnMainQueue(^{
    UIView<ABI36_0_0RCTComponentViewProtocol> *rootView =
        [mountingManager.componentViewRegistry componentViewByTag:surface.rootTag];
    [mountingManager.componentViewRegistry enqueueComponentViewWithComponentHandle:RootShadowNode::Handle()
                                                                               tag:surface.rootTag
                                                                     componentView:rootView];
  });

  [surface _unsetStage:(ABI36_0_0RCTSurfaceStagePrepared | ABI36_0_0RCTSurfaceStageMounted)];
}

- (void)_startAllSurfaces
{
  [_surfaceRegistry enumerateWithBlock:^(NSEnumerator<ABI36_0_0RCTFabricSurface *> *enumerator) {
    for (ABI36_0_0RCTFabricSurface *surface in enumerator) {
      [self _startSurface:surface];
    }
  }];
}

- (void)_stopAllSurfaces
{
  [_surfaceRegistry enumerateWithBlock:^(NSEnumerator<ABI36_0_0RCTFabricSurface *> *enumerator) {
    for (ABI36_0_0RCTFabricSurface *surface in enumerator) {
      [self _stopSurface:surface];
    }
  }];
}

#pragma mark - ABI36_0_0RCTSchedulerDelegate

- (void)schedulerDidFinishTransaction:(ABI36_0_0facebook::ABI36_0_0React::MountingCoordinator::Shared const &)mountingCoordinator
{
  ABI36_0_0RCTFabricSurface *surface = [_surfaceRegistry surfaceForRootTag:mountingCoordinator->getSurfaceId()];

  [surface _setStage:ABI36_0_0RCTSurfaceStagePrepared];

  [_mountingManager scheduleTransaction:mountingCoordinator];
}

- (void)schedulerDidDispatchCommand:(ABI36_0_0facebook::ABI36_0_0React::ShadowView const &)shadowView
                        commandName:(std::string const &)commandName
                               args:(folly::dynamic const)args
{
  ABI36_0_0ReactTag tag = shadowView.tag;
  NSString *commandStr = [[NSString alloc] initWithUTF8String:commandName.c_str()];
  NSArray *argsArray = convertFollyDynamicToId(args);

  [self->_mountingManager dispatchCommand:tag commandName:commandStr args:argsArray];
}

- (void)addObserver:(id<ABI36_0_0RCTSurfacePresenterObserver>)observer
{
  std::unique_lock<better::shared_mutex> lock(_observerListMutex);
  [self->_observers addObject:observer];
}

- (void)removeObserver:(id<ABI36_0_0RCTSurfacePresenterObserver>)observer
{
  std::unique_lock<better::shared_mutex> lock(_observerListMutex);
  [self->_observers removeObject:observer];
}

#pragma mark - ABI36_0_0RCTMountingManagerDelegate

- (void)mountingManager:(ABI36_0_0RCTMountingManager *)mountingManager willMountComponentsWithRootTag:(ABI36_0_0ReactTag)rootTag
{
  ABI36_0_0RCTAssertMainQueue();

  std::shared_lock<better::shared_mutex> lock(_observerListMutex);
  for (id<ABI36_0_0RCTSurfacePresenterObserver> observer in _observers) {
    if ([observer respondsToSelector:@selector(willMountComponentsWithRootTag:)]) {
      [observer willMountComponentsWithRootTag:rootTag];
    }
  }
}

- (void)mountingManager:(ABI36_0_0RCTMountingManager *)mountingManager didMountComponentsWithRootTag:(ABI36_0_0ReactTag)rootTag
{
  ABI36_0_0RCTAssertMainQueue();

  ABI36_0_0RCTFabricSurface *surface = [_surfaceRegistry surfaceForRootTag:rootTag];
  ABI36_0_0RCTSurfaceStage stage = surface.stage;
  if (stage & ABI36_0_0RCTSurfaceStagePrepared) {
    // We have to progress the stage only if the preparing phase is done.
    if ([surface _setStage:ABI36_0_0RCTSurfaceStageMounted]) {
      UIView *rootComponentView = [_mountingManager.componentViewRegistry componentViewByTag:rootTag];
      surface.view.rootView = (ABI36_0_0RCTSurfaceRootView *)rootComponentView;
    }
  }

  std::shared_lock<better::shared_mutex> lock(_observerListMutex);
  for (id<ABI36_0_0RCTSurfacePresenterObserver> observer in _observers) {
    if ([observer respondsToSelector:@selector(didMountComponentsWithRootTag:)]) {
      [observer didMountComponentsWithRootTag:rootTag];
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
  }
}

- (void)handleJavaScriptDidLoadNotification:(NSNotification *)notification
{
  ABI36_0_0RCTBridge *bridge = notification.userInfo[@"bridge"];
  if (bridge != _batchedBridge) {
    _batchedBridge = bridge;

    [self _startAllSurfaces];
  }
}

@end
