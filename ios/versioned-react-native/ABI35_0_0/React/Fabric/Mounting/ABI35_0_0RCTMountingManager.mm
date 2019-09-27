/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI35_0_0RCTMountingManager.h"

#import <ReactABI35_0_0/ABI35_0_0RCTAssert.h>
#import <ReactABI35_0_0/ABI35_0_0RCTUtils.h>
#import <ReactABI35_0_0/core/LayoutableShadowNode.h>
#import <ReactABI35_0_0/debug/SystraceSection.h>

#import "ABI35_0_0RCTComponentViewProtocol.h"
#import "ABI35_0_0RCTComponentViewRegistry.h"
#import "ABI35_0_0RCTMountItemProtocol.h"

#import "ABI35_0_0RCTConversions.h"
#import "ABI35_0_0RCTCreateMountItem.h"
#import "ABI35_0_0RCTDeleteMountItem.h"
#import "ABI35_0_0RCTInsertMountItem.h"
#import "ABI35_0_0RCTRemoveMountItem.h"
#import "ABI35_0_0RCTUpdateEventEmitterMountItem.h"
#import "ABI35_0_0RCTUpdateLayoutMetricsMountItem.h"
#import "ABI35_0_0RCTUpdateLocalDataMountItem.h"
#import "ABI35_0_0RCTUpdatePropsMountItem.h"

using namespace facebook::ReactABI35_0_0;

@implementation ABI35_0_0RCTMountingManager

- (instancetype)init
{
  if (self = [super init]) {
    _componentViewRegistry = [[ABI35_0_0RCTComponentViewRegistry alloc] init];
  }

  return self;
}

- (void)performTransactionWithMutations:(facebook::ReactABI35_0_0::ShadowViewMutationList)mutations rootTag:(ReactABI35_0_0Tag)rootTag
{
  NSMutableArray<ABI35_0_0RCTMountItemProtocol> *mountItems;

  {
    // This section is measured separately from `_performMountItems:rootTag:` because that can be asynchronous.
    SystraceSection s("-[ABI35_0_0RCTMountingManager performTransactionWithMutations:rootTag:]");

    mountItems =
        [[NSMutableArray<ABI35_0_0RCTMountItemProtocol> alloc] initWithCapacity:mutations.size() * 2 /* ~ the worst case */];

    for (const auto &mutation : mutations) {
      switch (mutation.type) {
        case ShadowViewMutation::Create: {
          ABI35_0_0RCTCreateMountItem *mountItem =
              [[ABI35_0_0RCTCreateMountItem alloc] initWithComponentHandle:mutation.newChildShadowView.componentHandle
                                                              tag:mutation.newChildShadowView.tag];
          [mountItems addObject:mountItem];
          break;
        }

        case ShadowViewMutation::Delete: {
          ABI35_0_0RCTDeleteMountItem *mountItem =
              [[ABI35_0_0RCTDeleteMountItem alloc] initWithComponentHandle:mutation.oldChildShadowView.componentHandle
                                                              tag:mutation.oldChildShadowView.tag];
          [mountItems addObject:mountItem];
          break;
        }

        case ShadowViewMutation::Insert: {
          // Props
          [mountItems addObject:[[ABI35_0_0RCTUpdatePropsMountItem alloc] initWithTag:mutation.newChildShadowView.tag
                                                                    oldProps:nullptr
                                                                    newProps:mutation.newChildShadowView.props]];

          // EventEmitter
          [mountItems
              addObject:[[ABI35_0_0RCTUpdateEventEmitterMountItem alloc] initWithTag:mutation.newChildShadowView.tag
                                                               eventEmitter:mutation.newChildShadowView.eventEmitter]];

          // LocalData
          if (mutation.newChildShadowView.localData) {
            [mountItems
                addObject:[[ABI35_0_0RCTUpdateLocalDataMountItem alloc] initWithTag:mutation.newChildShadowView.tag
                                                              oldLocalData:nullptr
                                                              newLocalData:mutation.newChildShadowView.localData]];
          }

          // Layout
          if (mutation.newChildShadowView.layoutMetrics != EmptyLayoutMetrics) {
            [mountItems addObject:[[ABI35_0_0RCTUpdateLayoutMetricsMountItem alloc]
                                           initWithTag:mutation.newChildShadowView.tag
                                      oldLayoutMetrics:{}
                                      newLayoutMetrics:mutation.newChildShadowView.layoutMetrics]];
          }

          // Insertion
          ABI35_0_0RCTInsertMountItem *mountItem = [[ABI35_0_0RCTInsertMountItem alloc] initWithChildTag:mutation.newChildShadowView.tag
                                                                             parentTag:mutation.parentShadowView.tag
                                                                                 index:mutation.index];
          [mountItems addObject:mountItem];

          break;
        }

        case ShadowViewMutation::Remove: {
          ABI35_0_0RCTRemoveMountItem *mountItem = [[ABI35_0_0RCTRemoveMountItem alloc] initWithChildTag:mutation.oldChildShadowView.tag
                                                                             parentTag:mutation.parentShadowView.tag
                                                                                 index:mutation.index];
          [mountItems addObject:mountItem];
          break;
        }

        case ShadowViewMutation::Update: {
          auto oldChildShadowView = mutation.oldChildShadowView;
          auto newChildShadowView = mutation.newChildShadowView;

          // Props
          if (oldChildShadowView.props != newChildShadowView.props) {
            ABI35_0_0RCTUpdatePropsMountItem *mountItem =
                [[ABI35_0_0RCTUpdatePropsMountItem alloc] initWithTag:mutation.oldChildShadowView.tag
                                                    oldProps:mutation.oldChildShadowView.props
                                                    newProps:mutation.newChildShadowView.props];
            [mountItems addObject:mountItem];
          }

          // EventEmitter
          if (oldChildShadowView.eventEmitter != newChildShadowView.eventEmitter) {
            ABI35_0_0RCTUpdateEventEmitterMountItem *mountItem =
                [[ABI35_0_0RCTUpdateEventEmitterMountItem alloc] initWithTag:mutation.oldChildShadowView.tag
                                                       eventEmitter:mutation.oldChildShadowView.eventEmitter];
            [mountItems addObject:mountItem];
          }

          // LocalData
          if (oldChildShadowView.localData != newChildShadowView.localData) {
            ABI35_0_0RCTUpdateLocalDataMountItem *mountItem =
                [[ABI35_0_0RCTUpdateLocalDataMountItem alloc] initWithTag:newChildShadowView.tag
                                                    oldLocalData:oldChildShadowView.localData
                                                    newLocalData:newChildShadowView.localData];
            [mountItems addObject:mountItem];
          }

          // Layout
          if (oldChildShadowView.layoutMetrics != newChildShadowView.layoutMetrics) {
            ABI35_0_0RCTUpdateLayoutMetricsMountItem *mountItem =
                [[ABI35_0_0RCTUpdateLayoutMetricsMountItem alloc] initWithTag:mutation.oldChildShadowView.tag
                                                    oldLayoutMetrics:oldChildShadowView.layoutMetrics
                                                    newLayoutMetrics:newChildShadowView.layoutMetrics];
            [mountItems addObject:mountItem];
          }

          break;
        }
      }
    }
  }

  ABI35_0_0RCTExecuteOnMainQueue(^{
    [self _performMountItems:mountItems rootTag:rootTag];
  });
}

- (void)_performMountItems:(NSArray<ABI35_0_0RCTMountItemProtocol> *)mountItems rootTag:(ReactABI35_0_0Tag)rootTag
{
  SystraceSection s("-[ABI35_0_0RCTMountingManager _performMountItems:rootTag:]");
  ABI35_0_0RCTAssertMainQueue();

  [self.delegate mountingManager:self willMountComponentsWithRootTag:rootTag];

  for (id<ABI35_0_0RCTMountItemProtocol> mountItem in mountItems) {
    [mountItem executeWithRegistry:_componentViewRegistry];
  }

  [self.delegate mountingManager:self didMountComponentsWithRootTag:rootTag];
}

- (void)optimisticallyCreateComponentViewWithComponentHandle:(ComponentHandle)componentHandle
{
  if (ABI35_0_0RCTIsMainQueue()) {
    // There is no reason to allocate views ahead of time on the main thread.
    return;
  }

  ABI35_0_0RCTExecuteOnMainQueue(^{
    [self->_componentViewRegistry optimisticallyCreateComponentViewWithComponentHandle:componentHandle];
  });
}

@end
