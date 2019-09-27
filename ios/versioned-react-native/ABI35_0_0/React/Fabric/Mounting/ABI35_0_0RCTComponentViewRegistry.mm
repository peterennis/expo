/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI35_0_0RCTComponentViewRegistry.h"

#import <Foundation/NSMapTable.h>
#import <ReactABI35_0_0/ABI35_0_0RCTAssert.h>

using namespace facebook::ReactABI35_0_0;

#define LEGACY_UIMANAGER_INTEGRATION_ENABLED 1

#ifdef LEGACY_UIMANAGER_INTEGRATION_ENABLED

#import <ReactABI35_0_0/ABI35_0_0RCTBridge+Private.h>
#import <ReactABI35_0_0/ABI35_0_0RCTUIManager.h>

/**
 * Warning: This is a total hack and temporary solution.
 * Unless we have a pure Fabric-based implementation of UIManager commands
 * delivery pipeline, we have to leverage existing infra. This code tricks
 * legacy UIManager by registering all Fabric-managed views in it,
 * hence existing command-delivery infra can reach "foreign" views using
 * the old pipeline.
 */
@interface ABI35_0_0RCTUIManager ()
- (NSMutableDictionary<NSNumber *, UIView *> *)viewRegistry;
@end

@interface ABI35_0_0RCTUIManager (Hack)

+ (void)registerView:(UIView *)view;
+ (void)unregisterView:(UIView *)view;

@end

@implementation ABI35_0_0RCTUIManager (Hack)

+ (void)registerView:(UIView *)view
{
  if (!view) {
    return;
  }

  ABI35_0_0RCTUIManager *uiManager = [[ABI35_0_0RCTBridge currentBridge] uiManager];
  view.ReactABI35_0_0Tag = @(view.tag);
  [uiManager.viewRegistry setObject:view forKey:@(view.tag)];
}

+ (void)unregisterView:(UIView *)view
{
  if (!view) {
    return;
  }

  ABI35_0_0RCTUIManager *uiManager = [[ABI35_0_0RCTBridge currentBridge] uiManager];
  view.ReactABI35_0_0Tag = nil;
  [uiManager.viewRegistry removeObjectForKey:@(view.tag)];
}

@end

#endif

const NSInteger ABI35_0_0RCTComponentViewRegistryRecyclePoolMaxSize = 1024;

@implementation ABI35_0_0RCTComponentViewRegistry {
  NSMapTable<id /* ReactABI35_0_0Tag */, UIView<ABI35_0_0RCTComponentViewProtocol> *> *_registry;
  NSMapTable<id /* ComponentHandle */, NSHashTable<UIView<ABI35_0_0RCTComponentViewProtocol> *> *> *_recyclePool;
}

- (instancetype)init
{
  if (self = [super init]) {
    _registry = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsIntegerPersonality | NSPointerFunctionsOpaqueMemory
                                      valueOptions:NSPointerFunctionsObjectPersonality];
    _recyclePool =
        [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaquePersonality | NSPointerFunctionsOpaqueMemory
                              valueOptions:NSPointerFunctionsObjectPersonality];
    _componentViewFactory = [ABI35_0_0RCTComponentViewFactory standardComponentViewFactory];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidReceiveMemoryWarningNotification)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
  }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIView<ABI35_0_0RCTComponentViewProtocol> *)dequeueComponentViewWithComponentHandle:(ComponentHandle)componentHandle
                                                                          tag:(ReactABI35_0_0Tag)tag
{
  ABI35_0_0RCTAssertMainQueue();

  ABI35_0_0RCTAssert(
      ![_registry objectForKey:(__bridge id)(void *)tag],
      @"ABI35_0_0RCTComponentViewRegistry: Attempt to dequeue already registered component.");

  UIView<ABI35_0_0RCTComponentViewProtocol> *componentView = [self _dequeueComponentViewWithComponentHandle:componentHandle];
  componentView.tag = tag;
  [_registry setObject:componentView forKey:(__bridge id)(void *)tag];

#ifdef LEGACY_UIMANAGER_INTEGRATION_ENABLED
  [ABI35_0_0RCTUIManager registerView:componentView];
#endif

  return componentView;
}

- (void)enqueueComponentViewWithComponentHandle:(ComponentHandle)componentHandle
                                            tag:(ReactABI35_0_0Tag)tag
                                  componentView:(UIView<ABI35_0_0RCTComponentViewProtocol> *)componentView
{
  ABI35_0_0RCTAssertMainQueue();

  ABI35_0_0RCTAssert(
      [_registry objectForKey:(__bridge id)(void *)tag],
      @"ABI35_0_0RCTComponentViewRegistry: Attempt to enqueue unregistered component.");

#ifdef LEGACY_UIMANAGER_INTEGRATION_ENABLED
  [ABI35_0_0RCTUIManager unregisterView:componentView];
#endif

  [_registry removeObjectForKey:(__bridge id)(void *)tag];
  componentView.tag = 0;
  [self _enqueueComponentViewWithComponentHandle:componentHandle componentView:componentView];
}

- (void)optimisticallyCreateComponentViewWithComponentHandle:(ComponentHandle)componentHandle
{
  ABI35_0_0RCTAssertMainQueue();
  [self _enqueueComponentViewWithComponentHandle:componentHandle
                                   componentView:[self.componentViewFactory
                                                     createComponentViewWithComponentHandle:componentHandle]];
}

- (UIView<ABI35_0_0RCTComponentViewProtocol> *)componentViewByTag:(ReactABI35_0_0Tag)tag
{
  ABI35_0_0RCTAssertMainQueue();
  return [_registry objectForKey:(__bridge id)(void *)tag];
}

- (ReactABI35_0_0Tag)tagByComponentView:(UIView<ABI35_0_0RCTComponentViewProtocol> *)componentView
{
  ABI35_0_0RCTAssertMainQueue();
  return componentView.tag;
}

- (nullable UIView<ABI35_0_0RCTComponentViewProtocol> *)_dequeueComponentViewWithComponentHandle:(ComponentHandle)componentHandle
{
  ABI35_0_0RCTAssertMainQueue();
  NSHashTable<UIView<ABI35_0_0RCTComponentViewProtocol> *> *componentViews =
      [_recyclePool objectForKey:(__bridge id)(void *)componentHandle];
  if (!componentViews || componentViews.count == 0) {
    return [self.componentViewFactory createComponentViewWithComponentHandle:componentHandle];
  }

  UIView<ABI35_0_0RCTComponentViewProtocol> *componentView = [componentViews anyObject];
  [componentViews removeObject:componentView];
  return componentView;
}

- (void)_enqueueComponentViewWithComponentHandle:(ComponentHandle)componentHandle
                                   componentView:(UIView<ABI35_0_0RCTComponentViewProtocol> *)componentView
{
  ABI35_0_0RCTAssertMainQueue();
  [componentView prepareForRecycle];

  NSHashTable<UIView<ABI35_0_0RCTComponentViewProtocol> *> *componentViews =
      [_recyclePool objectForKey:(__bridge id)(void *)componentHandle];
  if (!componentViews) {
    componentViews = [NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPersonality];
    [_recyclePool setObject:componentViews forKey:(__bridge id)(void *)componentHandle];
  }

  if (componentViews.count >= ABI35_0_0RCTComponentViewRegistryRecyclePoolMaxSize) {
    return;
  }

  [componentViews addObject:componentView];
}

- (void)handleApplicationDidReceiveMemoryWarningNotification
{
  [_recyclePool removeAllObjects];
}

@end
