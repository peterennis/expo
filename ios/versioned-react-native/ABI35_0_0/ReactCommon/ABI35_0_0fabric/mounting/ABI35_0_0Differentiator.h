// Copyright (c) Facebook, Inc. and its affiliates.

// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

#pragma once

#include <ReactABI35_0_0/core/ShadowNode.h>
#include <ReactABI35_0_0/mounting/ShadowViewMutation.h>

namespace facebook {
namespace ReactABI35_0_0 {

/*
 * Calculates a list of view mutations which describes how the old
 * `ShadowTree` can be transformed to the new one.
 * The list of mutations might be and might not be optimal.
 */
ShadowViewMutationList calculateShadowViewMutations(
    const ShadowNode &oldRootShadowNode,
    const ShadowNode &newRootShadowNode);

} // namespace ReactABI35_0_0
} // namespace facebook
