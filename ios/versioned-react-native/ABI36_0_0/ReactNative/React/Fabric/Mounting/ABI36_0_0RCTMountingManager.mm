/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI36_0_0RCTMountingManager.h"

#import <better/map.h>

#import <ABI36_0_0React/ABI36_0_0RCTAssert.h>
#import <ABI36_0_0React/ABI36_0_0RCTFollyConvert.h>
#import <ABI36_0_0React/ABI36_0_0RCTUtils.h>
#import <ABI36_0_0React/core/LayoutableShadowNode.h>
#import <ABI36_0_0React/core/RawProps.h>
#import <ABI36_0_0React/debug/SystraceSection.h>

#import "ABI36_0_0RCTComponentViewProtocol.h"
#import "ABI36_0_0RCTComponentViewRegistry.h"
#import "ABI36_0_0RCTConversions.h"

using namespace ABI36_0_0facebook;
using namespace ABI36_0_0facebook::ABI36_0_0React;

// `Create` instruction
static void ABI36_0_0RNCreateMountInstruction(ShadowViewMutation const &mutation, ABI36_0_0RCTComponentViewRegistry *registry)
{
  [registry dequeueComponentViewWithComponentHandle:mutation.newChildShadowView.componentHandle
                                                tag:mutation.newChildShadowView.tag];
}

// `Delete` instruction
static void ABI36_0_0RNDeleteMountInstruction(ShadowViewMutation const &mutation, ABI36_0_0RCTComponentViewRegistry *registry)
{
  auto const &oldChildShadowView = mutation.oldChildShadowView;
  UIView<ABI36_0_0RCTComponentViewProtocol> *componentView = [registry componentViewByTag:oldChildShadowView.tag];

  assert(componentView != nil && "Attempt to delete unregistered component.");

  [registry enqueueComponentViewWithComponentHandle:oldChildShadowView.componentHandle
                                                tag:oldChildShadowView.tag
                                      componentView:componentView];
}

// `Insert` instruction
static void ABI36_0_0RNInsertMountInstruction(ShadowViewMutation const &mutation, ABI36_0_0RCTComponentViewRegistry *registry)
{
  auto const &newShadowView = mutation.newChildShadowView;
  auto const &parentShadowView = mutation.parentShadowView;

  UIView<ABI36_0_0RCTComponentViewProtocol> *childComponentView = [registry componentViewByTag:newShadowView.tag];
  UIView<ABI36_0_0RCTComponentViewProtocol> *parentComponentView = [registry componentViewByTag:parentShadowView.tag];

  assert(childComponentView != nil && "Attempt to mount unregistered component.");
  assert(parentComponentView != nil && "Attempt to mount into unregistered component.");

  [parentComponentView mountChildComponentView:childComponentView index:mutation.index];
}

// `Remove` instruction
static void ABI36_0_0RNRemoveMountInstruction(ShadowViewMutation const &mutation, ABI36_0_0RCTComponentViewRegistry *registry)
{
  auto const &oldShadowView = mutation.oldChildShadowView;
  auto const &parentShadowView = mutation.parentShadowView;

  UIView<ABI36_0_0RCTComponentViewProtocol> *childComponentView = [registry componentViewByTag:oldShadowView.tag];
  UIView<ABI36_0_0RCTComponentViewProtocol> *parentComponentView = [registry componentViewByTag:parentShadowView.tag];

  assert(childComponentView != nil && "Attempt to unmount unregistered component.");
  assert(parentComponentView != nil && "Attempt to unmount from unregistered component.");

  [parentComponentView unmountChildComponentView:childComponentView index:mutation.index];
}

// `Update Props` instruction
static void ABI36_0_0RNUpdatePropsMountInstruction(ShadowViewMutation const &mutation, ABI36_0_0RCTComponentViewRegistry *registry)
{
  auto const &oldShadowView = mutation.oldChildShadowView;
  auto const &newShadowView = mutation.newChildShadowView;
  UIView<ABI36_0_0RCTComponentViewProtocol> *componentView = [registry componentViewByTag:newShadowView.tag];
  [componentView updateProps:newShadowView.props oldProps:oldShadowView.props];
}

// `Update EventEmitter` instruction
static void ABI36_0_0RNUpdateEventEmitterMountInstruction(ShadowViewMutation const &mutation, ABI36_0_0RCTComponentViewRegistry *registry)
{
  auto const &newShadowView = mutation.newChildShadowView;
  UIView<ABI36_0_0RCTComponentViewProtocol> *componentView = [registry componentViewByTag:newShadowView.tag];
  [componentView updateEventEmitter:newShadowView.eventEmitter];
}

// `Update LayoutMetrics` instruction
static void ABI36_0_0RNUpdateLayoutMetricsMountInstruction(
    ShadowViewMutation const &mutation,
    ABI36_0_0RCTComponentViewRegistry *registry)
{
  auto const &oldShadowView = mutation.oldChildShadowView;
  auto const &newShadowView = mutation.newChildShadowView;
  UIView<ABI36_0_0RCTComponentViewProtocol> *componentView = [registry componentViewByTag:newShadowView.tag];
  [componentView updateLayoutMetrics:newShadowView.layoutMetrics oldLayoutMetrics:oldShadowView.layoutMetrics];
}

// `Update LocalData` instruction
static void ABI36_0_0RNUpdateLocalDataMountInstruction(ShadowViewMutation const &mutation, ABI36_0_0RCTComponentViewRegistry *registry)
{
  auto const &oldShadowView = mutation.oldChildShadowView;
  auto const &newShadowView = mutation.newChildShadowView;
  UIView<ABI36_0_0RCTComponentViewProtocol> *componentView = [registry componentViewByTag:newShadowView.tag];
  [componentView updateLocalData:newShadowView.localData oldLocalData:oldShadowView.localData];
}

// `Update State` instruction
static void ABI36_0_0RNUpdateStateMountInstruction(ShadowViewMutation const &mutation, ABI36_0_0RCTComponentViewRegistry *registry)
{
  auto const &oldShadowView = mutation.oldChildShadowView;
  auto const &newShadowView = mutation.newChildShadowView;
  UIView<ABI36_0_0RCTComponentViewProtocol> *componentView = [registry componentViewByTag:newShadowView.tag];
  [componentView updateState:newShadowView.state oldState:oldShadowView.state];
}

// `Finalize Updates` instruction
static void ABI36_0_0RNFinalizeUpdatesMountInstruction(
    ShadowViewMutation const &mutation,
    ABI36_0_0RNComponentViewUpdateMask mask,
    ABI36_0_0RCTComponentViewRegistry *registry)
{
  auto const &newShadowView = mutation.newChildShadowView;
  UIView<ABI36_0_0RCTComponentViewProtocol> *componentView = [registry componentViewByTag:newShadowView.tag];
  [componentView finalizeUpdates:mask];
}

// `Update` instruction
static void ABI36_0_0RNPerformMountInstructions(ShadowViewMutationList const &mutations, ABI36_0_0RCTComponentViewRegistry *registry)
{
  SystraceSection s("ABI36_0_0RNPerformMountInstructions");

  for (auto const &mutation : mutations) {
    switch (mutation.type) {
      case ShadowViewMutation::Create: {
        ABI36_0_0RNCreateMountInstruction(mutation, registry);
        break;
      }
      case ShadowViewMutation::Delete: {
        ABI36_0_0RNDeleteMountInstruction(mutation, registry);
        break;
      }
      case ShadowViewMutation::Insert: {
        ABI36_0_0RNUpdatePropsMountInstruction(mutation, registry);
        ABI36_0_0RNUpdateEventEmitterMountInstruction(mutation, registry);
        ABI36_0_0RNUpdateLocalDataMountInstruction(mutation, registry);
        ABI36_0_0RNUpdateStateMountInstruction(mutation, registry);
        ABI36_0_0RNUpdateLayoutMetricsMountInstruction(mutation, registry);
        ABI36_0_0RNFinalizeUpdatesMountInstruction(mutation, ABI36_0_0RNComponentViewUpdateMaskAll, registry);
        ABI36_0_0RNInsertMountInstruction(mutation, registry);
        break;
      }
      case ShadowViewMutation::Remove: {
        ABI36_0_0RNRemoveMountInstruction(mutation, registry);
        break;
      }
      case ShadowViewMutation::Update: {
        auto const &oldChildShadowView = mutation.oldChildShadowView;
        auto const &newChildShadowView = mutation.newChildShadowView;

        auto mask = ABI36_0_0RNComponentViewUpdateMask{};

        if (oldChildShadowView.props != newChildShadowView.props) {
          ABI36_0_0RNUpdatePropsMountInstruction(mutation, registry);
          mask |= ABI36_0_0RNComponentViewUpdateMaskProps;
        }
        if (oldChildShadowView.eventEmitter != newChildShadowView.eventEmitter) {
          ABI36_0_0RNUpdateEventEmitterMountInstruction(mutation, registry);
          mask |= ABI36_0_0RNComponentViewUpdateMaskEventEmitter;
        }
        if (oldChildShadowView.localData != newChildShadowView.localData) {
          ABI36_0_0RNUpdateLocalDataMountInstruction(mutation, registry);
          mask |= ABI36_0_0RNComponentViewUpdateMaskLocalData;
        }
        if (oldChildShadowView.state != newChildShadowView.state) {
          ABI36_0_0RNUpdateStateMountInstruction(mutation, registry);
          mask |= ABI36_0_0RNComponentViewUpdateMaskState;
        }
        if (oldChildShadowView.layoutMetrics != newChildShadowView.layoutMetrics) {
          ABI36_0_0RNUpdateLayoutMetricsMountInstruction(mutation, registry);
          mask |= ABI36_0_0RNComponentViewUpdateMaskLayoutMetrics;
        }

        if (mask != ABI36_0_0RNComponentViewUpdateMaskNone) {
          ABI36_0_0RNFinalizeUpdatesMountInstruction(mutation, mask, registry);
        }

        break;
      }
    }
  }
}

@implementation ABI36_0_0RCTMountingManager

- (instancetype)init
{
  if (self = [super init]) {
    _componentViewRegistry = [[ABI36_0_0RCTComponentViewRegistry alloc] init];
  }

  return self;
}

- (void)scheduleTransaction:(MountingCoordinator::Shared const &)mountingCoordinator
{
  if (ABI36_0_0RCTIsMainQueue()) {
    // Already on the proper thread, so:
    // * No need to do a thread jump;
    // * No need to do expensive copy of all mutations;
    // * No need to allocate a block.
    [self mountMutations:mountingCoordinator];
    return;
  }

  auto mountingCoordinatorCopy = mountingCoordinator;
  ABI36_0_0RCTExecuteOnMainQueue(^{
    ABI36_0_0RCTAssertMainQueue();
    [self mountMutations:mountingCoordinatorCopy];
  });
}

- (void)dispatchCommand:(ABI36_0_0ReactTag)ABI36_0_0ReactTag commandName:(NSString *)commandName args:(NSArray *)args
{
  if (ABI36_0_0RCTIsMainQueue()) {
    // Already on the proper thread, so:
    // * No need to do a thread jump;
    // * No need to allocate a block.
    [self synchronouslyDispatchCommandOnUIThread:ABI36_0_0ReactTag commandName:commandName args:args];
    return;
  }

  ABI36_0_0RCTExecuteOnMainQueue(^{
    ABI36_0_0RCTAssertMainQueue();
    [self synchronouslyDispatchCommandOnUIThread:ABI36_0_0ReactTag commandName:commandName args:args];
  });
}

- (void)mountMutations:(MountingCoordinator::Shared const &)mountingCoordinator
{
  SystraceSection s("-[ABI36_0_0RCTMountingManager mountMutations:]");

  auto transaction = mountingCoordinator->pullTransaction();
  if (!transaction.has_value()) {
    return;
  }

  auto surfaceId = transaction->getSurfaceId();

  ABI36_0_0RCTAssertMainQueue();
  [self.delegate mountingManager:self willMountComponentsWithRootTag:surfaceId];
  ABI36_0_0RNPerformMountInstructions(transaction->getMutations(), self.componentViewRegistry);
  [self.delegate mountingManager:self didMountComponentsWithRootTag:surfaceId];
}

- (void)synchronouslyUpdateViewOnUIThread:(ABI36_0_0ReactTag)ABI36_0_0ReactTag
                             changedProps:(NSDictionary *)props
                      componentDescriptor:(const ComponentDescriptor &)componentDescriptor
{
  ABI36_0_0RCTAssertMainQueue();
  UIView<ABI36_0_0RCTComponentViewProtocol> *componentView = [_componentViewRegistry componentViewByTag:ABI36_0_0ReactTag];
  SharedProps oldProps = [componentView props];
  SharedProps newProps = componentDescriptor.cloneProps(oldProps, RawProps(convertIdToFollyDynamic(props)));
  [componentView updateProps:newProps oldProps:oldProps];
}

- (void)synchronouslyDispatchCommandOnUIThread:(ABI36_0_0ReactTag)ABI36_0_0ReactTag
                                   commandName:(NSString *)commandName
                                          args:(NSArray *)args
{
  ABI36_0_0RCTAssertMainQueue();
  UIView<ABI36_0_0RCTComponentViewProtocol> *componentView = [_componentViewRegistry componentViewByTag:ABI36_0_0ReactTag];
  [componentView handleCommand:commandName args:args];
}

@end
