/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <ABI36_0_0React/components/view/AccessibilityPrimitives.h>
#include <ABI36_0_0React/core/Props.h>
#include <ABI36_0_0React/core/ABI36_0_0ReactPrimitives.h>
#include <ABI36_0_0React/debug/DebugStringConvertible.h>

namespace ABI36_0_0facebook {
namespace ABI36_0_0React {

class AccessibilityProps {
 public:
  AccessibilityProps() = default;
  AccessibilityProps(
      AccessibilityProps const &sourceProps,
      RawProps const &rawProps);

#pragma mark - Props

  bool const accessible{false};
  AccessibilityTraits const accessibilityTraits{AccessibilityTraits::None};
  std::string const accessibilityLabel{""};
  std::string const accessibilityHint{""};
  std::vector<std::string> const accessibilityActions{};
  bool const accessibilityViewIsModal{false};
  bool const accessibilityElementsHidden{false};
  bool const accessibilityIgnoresInvertColors{false};
  std::string const testId{""};

#pragma mark - DebugStringConvertible

#if ABI36_0_0RN_DEBUG_STRING_CONVERTIBLE
  SharedDebugStringConvertibleList getDebugProps() const;
#endif
};

} // namespace ABI36_0_0React
} // namespace ABI36_0_0facebook
