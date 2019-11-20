/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <memory>

#include <ABI36_0_0React/attributedstring/AttributedString.h>
#include <ABI36_0_0React/attributedstring/ParagraphAttributes.h>
#include <ABI36_0_0React/core/LayoutConstraints.h>
#include <ABI36_0_0React/utils/ContextContainer.h>

namespace ABI36_0_0facebook {
namespace ABI36_0_0React {

class TextLayoutManager;

using SharedTextLayoutManager = std::shared_ptr<const TextLayoutManager>;

/*
 * Cross platform facade for iOS-specific ABI36_0_0RCTTTextLayoutManager.
 */
class TextLayoutManager {
 public:
  TextLayoutManager(ContextContainer::Shared const &contextContainer);
  ~TextLayoutManager();

  /*
   * Measures `attributedString` using native text rendering infrastructure.
   */
  Size measure(
      AttributedString attributedString,
      ParagraphAttributes paragraphAttributes,
      LayoutConstraints layoutConstraints) const;

  /*
   * Returns an opaque pointer to platform-specific TextLayoutManager.
   * Is used on a native views layer to delegate text rendering to the manager.
   */
  void *getNativeTextLayoutManager() const;

 private:
  void *self_;
};

} // namespace ABI36_0_0React
} // namespace ABI36_0_0facebook
