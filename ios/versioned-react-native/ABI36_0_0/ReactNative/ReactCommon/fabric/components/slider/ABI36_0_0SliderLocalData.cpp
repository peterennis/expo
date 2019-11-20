/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include "ABI36_0_0SliderLocalData.h"

#include <ABI36_0_0React/components/image/conversions.h>
#include <ABI36_0_0React/debug/debugStringConvertibleUtils.h>

namespace ABI36_0_0facebook {
namespace ABI36_0_0React {

ImageSource SliderLocalData::getTrackImageSource() const {
  return trackImageSource_;
}

const ImageRequest &SliderLocalData::getTrackImageRequest() const {
  return trackImageRequest_;
}

ImageSource SliderLocalData::getMinimumTrackImageSource() const {
  return minimumTrackImageSource_;
}

const ImageRequest &SliderLocalData::getMinimumTrackImageRequest() const {
  return minimumTrackImageRequest_;
}

ImageSource SliderLocalData::getMaximumTrackImageSource() const {
  return maximumTrackImageSource_;
}

const ImageRequest &SliderLocalData::getMaximumTrackImageRequest() const {
  return maximumTrackImageRequest_;
}

ImageSource SliderLocalData::getThumbImageSource() const {
  return thumbImageSource_;
}

const ImageRequest &SliderLocalData::getThumbImageRequest() const {
  return thumbImageRequest_;
}

#pragma mark - DebugStringConvertible

#if ABI36_0_0RN_DEBUG_STRING_CONVERTIBLE
std::string SliderLocalData::getDebugName() const {
  return "SliderLocalData";
}

SharedDebugStringConvertibleList SliderLocalData::getDebugProps() const {
  return {
      debugStringConvertibleItem("trackImageSource", trackImageSource_),
      debugStringConvertibleItem(
          "minimumTrackImageSource", minimumTrackImageSource_),
      debugStringConvertibleItem(
          "maximumTrackImageSource", maximumTrackImageSource_),
      debugStringConvertibleItem("thumbImageSource", thumbImageSource_),
  };
}
#endif

} // namespace ABI36_0_0React
} // namespace ABI36_0_0facebook
