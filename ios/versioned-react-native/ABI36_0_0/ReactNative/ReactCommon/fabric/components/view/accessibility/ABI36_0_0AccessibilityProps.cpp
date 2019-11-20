/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include "ABI36_0_0AccessibilityProps.h"

#include <ABI36_0_0React/components/view/accessibilityPropsConversions.h>
#include <ABI36_0_0React/components/view/propsConversions.h>
#include <ABI36_0_0React/core/propsConversions.h>
#include <ABI36_0_0React/debug/debugStringConvertibleUtils.h>

namespace ABI36_0_0facebook {
namespace ABI36_0_0React {

AccessibilityProps::AccessibilityProps(
    AccessibilityProps const &sourceProps,
    RawProps const &rawProps)
    : accessible(
          convertRawProp(rawProps, "accessible", sourceProps.accessible)),
      accessibilityLabel(convertRawProp(
          rawProps,
          "accessibilityLabel",
          sourceProps.accessibilityLabel)),
      accessibilityHint(convertRawProp(
          rawProps,
          "accessibilityHint",
          sourceProps.accessibilityHint)),
      accessibilityActions(convertRawProp(
          rawProps,
          "accessibilityActions",
          sourceProps.accessibilityActions)),
      accessibilityViewIsModal(convertRawProp(
          rawProps,
          "accessibilityViewIsModal",
          sourceProps.accessibilityViewIsModal)),
      accessibilityElementsHidden(convertRawProp(
          rawProps,
          "accessibilityElementsHidden",
          sourceProps.accessibilityElementsHidden)),
      accessibilityIgnoresInvertColors(convertRawProp(
          rawProps,
          "accessibilityIgnoresInvertColors",
          sourceProps.accessibilityIgnoresInvertColors)),
      testId(convertRawProp(rawProps, "testId", sourceProps.testId)) {}

#pragma mark - DebugStringConvertible

#if ABI36_0_0RN_DEBUG_STRING_CONVERTIBLE
SharedDebugStringConvertibleList AccessibilityProps::getDebugProps() const {
  auto const &defaultProps = AccessibilityProps();
  return SharedDebugStringConvertibleList{
      debugStringConvertibleItem("testId", testId, defaultProps.testId),
  };
}
#endif // ABI36_0_0RN_DEBUG_STRING_CONVERTIBLE

} // namespace ABI36_0_0React
} // namespace ABI36_0_0facebook
