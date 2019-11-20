/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <ABI36_0_0React/core/LocalData.h>
#include <ABI36_0_0React/imagemanager/ImageRequest.h>
#include <ABI36_0_0React/imagemanager/primitives.h>

namespace ABI36_0_0facebook {
namespace ABI36_0_0React {

class SliderLocalData;

using SharedSliderLocalData = std::shared_ptr<const SliderLocalData>;

/*
 * LocalData for <Slider> component.
 * Represents the image request state and (possible) retrieved image bitmap.
 */
class SliderLocalData : public LocalData {
 public:
  SliderLocalData(
      const ImageSource &trackImageSource,
      ImageRequest trackImageRequest,
      const ImageSource &minimumTrackImageSource,
      ImageRequest minimumTrackImageRequest,
      const ImageSource &maximumTrackImageSource,
      ImageRequest maximumTrackImageRequest,
      const ImageSource &thumbImageSource,
      ImageRequest thumbImageRequest)
      : trackImageSource_(trackImageSource),
        trackImageRequest_(std::move(trackImageRequest)),
        minimumTrackImageSource_(minimumTrackImageSource),
        minimumTrackImageRequest_(std::move(minimumTrackImageRequest)),
        maximumTrackImageSource_(maximumTrackImageSource),
        maximumTrackImageRequest_(std::move(maximumTrackImageRequest)),
        thumbImageSource_(thumbImageSource),
        thumbImageRequest_(std::move(thumbImageRequest)){};

  /*
   * Returns stored ImageSource object.
   */
  ImageSource getTrackImageSource() const;

  /*
   * Exposes for reading stored `ImageRequest` object.
   * `ImageRequest` object cannot be copied or moved from `ImageLocalData`.
   */
  const ImageRequest &getTrackImageRequest() const;

  /*
   * Returns stored ImageSource object.
   */
  ImageSource getMinimumTrackImageSource() const;

  /*
   * Exposes for reading stored `ImageRequest` object.
   * `ImageRequest` object cannot be copied or moved from `ImageLocalData`.
   */
  const ImageRequest &getMinimumTrackImageRequest() const;

  /*
   * Returns stored ImageSource object.
   */
  ImageSource getMaximumTrackImageSource() const;

  /*
   * Exposes for reading stored `ImageRequest` object.
   * `ImageRequest` object cannot be copied or moved from `ImageLocalData`.
   */
  const ImageRequest &getMaximumTrackImageRequest() const;

  /*
   * Returns stored ImageSource object.
   */
  ImageSource getThumbImageSource() const;

  /*
   * Exposes for reading stored `ImageRequest` object.
   * `ImageRequest` object cannot be copied or moved from `ImageLocalData`.
   */
  const ImageRequest &getThumbImageRequest() const;

#pragma mark - DebugStringConvertible

#if ABI36_0_0RN_DEBUG_STRING_CONVERTIBLE
  std::string getDebugName() const override;
  SharedDebugStringConvertibleList getDebugProps() const override;
#endif

 private:
  ImageSource trackImageSource_;
  ImageRequest trackImageRequest_;
  ImageSource minimumTrackImageSource_;
  ImageRequest minimumTrackImageRequest_;
  ImageSource maximumTrackImageSource_;
  ImageRequest maximumTrackImageRequest_;
  ImageSource thumbImageSource_;
  ImageRequest thumbImageRequest_;
};

} // namespace ABI36_0_0React
} // namespace ABI36_0_0facebook
