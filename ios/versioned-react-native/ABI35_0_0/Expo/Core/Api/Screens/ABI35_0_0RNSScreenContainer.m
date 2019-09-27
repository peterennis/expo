#import "ABI35_0_0RNSScreenContainer.h"
#import "ABI35_0_0RNSScreen.h"

#import <ReactABI35_0_0/ABI35_0_0RCTUIManager.h>
#import <ReactABI35_0_0/ABI35_0_0RCTUIManagerObserverCoordinator.h>
#import <ReactABI35_0_0/ABI35_0_0RCTUIManagerUtils.h>

@interface ABI35_0_0RNSScreenContainerManager : ABI35_0_0RCTViewManager

- (void)markUpdated:(ABI35_0_0RNSScreenContainerView *)screen;

@end

@interface ABI35_0_0RNSScreenContainerView ()

@property (nonatomic, retain) UIViewController *controller;
@property (nonatomic, retain) NSMutableSet<ABI35_0_0RNSScreenView *> *activeScreens;
@property (nonatomic, retain) NSMutableArray<ABI35_0_0RNSScreenView *> *ReactABI35_0_0Subviews;

- (void)updateContainer;

@end

@implementation ABI35_0_0RNSScreenContainerView {
  BOOL _needUpdate;
  __weak ABI35_0_0RNSScreenContainerManager *_manager;
}

- (instancetype)initWithManager:(ABI35_0_0RNSScreenContainerManager *)manager
{
  if (self = [super init]) {
    _activeScreens = [NSMutableSet new];
    _ReactABI35_0_0Subviews = [NSMutableArray new];
    _controller = [[UIViewController alloc] init];
    _needUpdate = NO;
    _manager = manager;
    [self addSubview:_controller.view];
  }
  return self;
}

- (void)markChildUpdated
{
  // We want 'updateContainer' to be executed on main thread after all enqueued operations in
  // uimanager are complete. For that we collect all marked containers in manager class and enqueue
  // operation on ui thread that should run once all the updates are completed.
  if (!_needUpdate) {
    _needUpdate = YES;
    [_manager markUpdated:self];
  }
}

- (void)insertReactABI35_0_0Subview:(ABI35_0_0RNSScreenView *)subview atIndex:(NSInteger)atIndex
{
  subview.ReactABI35_0_0Superview = self;
  [_ReactABI35_0_0Subviews insertObject:subview atIndex:atIndex];
}

- (void)removeReactABI35_0_0Subview:(ABI35_0_0RNSScreenView *)subview
{
  subview.ReactABI35_0_0Superview = nil;
  [_ReactABI35_0_0Subviews removeObject:subview];
}

- (NSArray<UIView *> *)ReactABI35_0_0Subviews
{
  return _ReactABI35_0_0Subviews;
}

- (void)detachScreen:(ABI35_0_0RNSScreenView *)screen
{
  [screen.controller willMoveToParentViewController:nil];
  [screen.controller.view removeFromSuperview];
  [screen.controller removeFromParentViewController];
  [_activeScreens removeObject:screen];
}

- (void)attachScreen:(ABI35_0_0RNSScreenView *)screen
{
  [_controller addChildViewController:screen.controller];
  [_controller.view addSubview:screen.controller.view];
  [screen.controller didMoveToParentViewController:_controller];
  [_activeScreens addObject:screen];
}

- (void)updateContainer
{
  _needUpdate = NO;
  BOOL activeScreenRemoved = NO;
  // remove screens that are no longer active
  NSMutableSet *orphaned = [NSMutableSet setWithSet:_activeScreens];
  for (ABI35_0_0RNSScreenView *screen in _ReactABI35_0_0Subviews) {
    if (!screen.active && [_activeScreens containsObject:screen]) {
      activeScreenRemoved = YES;
      [self detachScreen:screen];
    }
    [orphaned removeObject:screen];
  }
  for (ABI35_0_0RNSScreenView *screen in orphaned) {
    activeScreenRemoved = YES;
    [self detachScreen:screen];
  }

  // detect if new screen is going to be activated
  BOOL activeScreenAdded = NO;
  for (ABI35_0_0RNSScreenView *screen in _ReactABI35_0_0Subviews) {
    if (screen.active && ![_activeScreens containsObject:screen]) {
      activeScreenAdded = YES;
    }
  }

  // if we are adding new active screen, we perform remounting of all already marked as active
  // this is done to mimick the effect UINavigationController has when willMoveToWindow:nil is
  // triggered before the animation starts
  if (activeScreenAdded) {
    for (ABI35_0_0RNSScreenView *screen in _ReactABI35_0_0Subviews) {
      if (screen.active && [_activeScreens containsObject:screen]) {
        [self detachScreen:screen];
        // disable interactions for the duration of transition
        screen.userInteractionEnabled = NO;
      }
    }

    // add new screens in order they are placed in subviews array
    for (ABI35_0_0RNSScreenView *screen in _ReactABI35_0_0Subviews) {
      if (screen.active) {
        [self attachScreen:screen];
      }
    }
  }

  // if we are down to one active screen it means the transitioning is over and we want to notify
  // the transition has finished
  if ((activeScreenRemoved || activeScreenAdded) && _activeScreens.count == 1) {
    ABI35_0_0RNSScreenView *singleActiveScreen = [_activeScreens anyObject];
    // restore interactions
    singleActiveScreen.userInteractionEnabled = YES;
    [singleActiveScreen notifyFinishTransitioning];
  }

  if ((activeScreenRemoved || activeScreenAdded) && _controller.presentedViewController == nil) {
    // if user has reachability enabled (one hand use) and the window is slided down the below
    // method will force it to slide back up as it is expected to happen with UINavController when
    // we push or pop views.
    // We only do that if `presentedViewController` is nil, as otherwise it'd mean that modal has
    // been presented on top of recently changed controller in which case the below method would
    // dismiss such a modal (e.g., permission modal or alert)
    [_controller dismissViewControllerAnimated:NO completion:nil];
  }
}

- (void)didUpdateReactABI35_0_0Subviews
{
  [self markChildUpdated];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  [self ReactABI35_0_0AddControllerToClosestParent:_controller];
  _controller.view.frame = self.bounds;
}

@end


@implementation ABI35_0_0RNSScreenContainerManager {
  NSMutableArray<ABI35_0_0RNSScreenContainerView *> *_markedContainers;
}

ABI35_0_0RCT_EXPORT_MODULE()

- (UIView *)view
{
  if (!_markedContainers) {
    _markedContainers = [NSMutableArray new];
  }
  return [[ABI35_0_0RNSScreenContainerView alloc] initWithManager:self];
}

- (void)markUpdated:(ABI35_0_0RNSScreenContainerView *)screen
{
  ABI35_0_0RCTAssertMainQueue();
  [_markedContainers addObject:screen];
  if ([_markedContainers count] == 1) {
    // we enqueue updates to be run on the main queue in order to make sure that
    // all this updates (new screens attached etc) are executed in one batch
    ABI35_0_0RCTExecuteOnMainQueue(^{
      for (ABI35_0_0RNSScreenContainerView *container in _markedContainers) {
        [container updateContainer];
      }
      [_markedContainers removeAllObjects];
    });
  }
}

@end
