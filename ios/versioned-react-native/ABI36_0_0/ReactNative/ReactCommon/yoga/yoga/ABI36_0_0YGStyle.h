/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the LICENSE
 * file in the root directory of this source tree.
 */
#pragma once
#include <algorithm>
#include <array>
#include <cstdint>
#include <type_traits>
#include "ABI36_0_0Bitfield.h"
#include "ABI36_0_0CompactValue.h"
#include "ABI36_0_0YGEnums.h"
#include "ABI36_0_0YGFloatOptional.h"
#include "ABI36_0_0Yoga-internal.h"
#include "ABI36_0_0Yoga.h"

class ABI36_0_0YGStyle {
  template <typename Enum>
  using Values =
      ABI36_0_0facebook::yoga::detail::Values<ABI36_0_0facebook::yoga::enums::count<Enum>()>;
  using CompactValue = ABI36_0_0facebook::yoga::detail::CompactValue;

public:
  using Dimensions = Values<ABI36_0_0YGDimension>;
  using Edges = Values<ABI36_0_0YGEdge>;

  template <typename T, T ABI36_0_0YGStyle::*Prop>
  struct Ref {
    ABI36_0_0YGStyle& style;
    operator T() const { return style.*Prop; }
    Ref<T, Prop>& operator=(T value) {
      style.*Prop = value;
      return *this;
    }
  };

  template <typename Idx, Values<Idx> ABI36_0_0YGStyle::*Prop>
  struct IdxRef {
    struct Ref {
      ABI36_0_0YGStyle& style;
      Idx idx;
      operator CompactValue() const { return (style.*Prop)[idx]; }
      operator ABI36_0_0YGValue() const { return (style.*Prop)[idx]; }
      Ref& operator=(CompactValue value) {
        (style.*Prop)[idx] = value;
        return *this;
      }
    };

    ABI36_0_0YGStyle& style;
    IdxRef<Idx, Prop>& operator=(const Values<Idx>& values) {
      style.*Prop = values;
      return *this;
    }
    operator const Values<Idx>&() const { return style.*Prop; }
    Ref operator[](Idx idx) { return {style, idx}; }
    CompactValue operator[](Idx idx) const { return (style.*Prop)[idx]; }
  };

  ABI36_0_0YGStyle() = default;
  ~ABI36_0_0YGStyle() = default;

private:
  static constexpr size_t directionIdx = 0;
  static constexpr size_t flexDirectionIdx = 1;
  static constexpr size_t justifyContentIdx = 2;
  static constexpr size_t alignContentIdx = 3;
  static constexpr size_t alignItemsIdx = 4;
  static constexpr size_t alignSelfIdx = 5;
  static constexpr size_t positionTypeIdx = 6;
  static constexpr size_t flexWrapIdx = 7;
  static constexpr size_t overflowIdx = 8;
  static constexpr size_t displayIdx = 9;
  using Flags = ABI36_0_0facebook::yoga::Bitfield<
      uint32_t,
      ABI36_0_0YGDirection,
      ABI36_0_0YGFlexDirection,
      ABI36_0_0YGJustify,
      ABI36_0_0YGAlign,
      ABI36_0_0YGAlign,
      ABI36_0_0YGAlign,
      ABI36_0_0YGPositionType,
      ABI36_0_0YGWrap,
      ABI36_0_0YGOverflow,
      ABI36_0_0YGDisplay>;

  Flags flags_ = {ABI36_0_0YGDirectionInherit,
                  ABI36_0_0YGFlexDirectionColumn,
                  ABI36_0_0YGJustifyFlexStart,
                  ABI36_0_0YGAlignFlexStart,
                  ABI36_0_0YGAlignStretch,
                  ABI36_0_0YGAlignAuto,
                  ABI36_0_0YGPositionTypeRelative,
                  ABI36_0_0YGWrapNoWrap,
                  ABI36_0_0YGOverflowVisible,
                  ABI36_0_0YGDisplayFlex};
  ABI36_0_0YGFloatOptional flex_ = {};
  ABI36_0_0YGFloatOptional flexGrow_ = {};
  ABI36_0_0YGFloatOptional flexShrink_ = {};
  CompactValue flexBasis_ = CompactValue::ofAuto();
  Edges margin_ = {};
  Edges position_ = {};
  Edges padding_ = {};
  Edges border_ = {};
  Dimensions dimensions_{CompactValue::ofAuto()};
  Dimensions minDimensions_ = {};
  Dimensions maxDimensions_ = {};
  // Yoga specific properties, not compatible with flexbox specification
  ABI36_0_0YGFloatOptional aspectRatio_ = {};

public:
  // for library users needing a type
  using ValueRepr = std::remove_reference<decltype(margin_[0])>::type;

  ABI36_0_0YGDirection direction() const { return flags_.at<directionIdx>(); }
  Flags::Ref<directionIdx> direction() { return flags_.at<directionIdx>(); }

  ABI36_0_0YGFlexDirection flexDirection() const {
    return flags_.at<flexDirectionIdx>();
  }
  Flags::Ref<flexDirectionIdx> flexDirection() {
    return flags_.at<flexDirectionIdx>();
  }

  ABI36_0_0YGJustify justifyContent() const { return flags_.at<justifyContentIdx>(); }
  Flags::Ref<justifyContentIdx> justifyContent() {
    return flags_.at<justifyContentIdx>();
  }

  ABI36_0_0YGAlign alignContent() const { return flags_.at<alignContentIdx>(); }
  Flags::Ref<alignContentIdx> alignContent() {
    return flags_.at<alignContentIdx>();
  }

  ABI36_0_0YGAlign alignItems() const { return flags_.at<alignItemsIdx>(); }
  Flags::Ref<alignItemsIdx> alignItems() { return flags_.at<alignItemsIdx>(); }

  ABI36_0_0YGAlign alignSelf() const { return flags_.at<alignSelfIdx>(); }
  Flags::Ref<alignSelfIdx> alignSelf() { return flags_.at<alignSelfIdx>(); }

  ABI36_0_0YGPositionType positionType() const { return flags_.at<positionTypeIdx>(); }
  Flags::Ref<positionTypeIdx> positionType() {
    return flags_.at<positionTypeIdx>();
  }

  ABI36_0_0YGWrap flexWrap() const { return flags_.at<flexWrapIdx>(); }
  Flags::Ref<flexWrapIdx> flexWrap() { return flags_.at<flexWrapIdx>(); }

  ABI36_0_0YGOverflow overflow() const { return flags_.at<overflowIdx>(); }
  Flags::Ref<overflowIdx> overflow() { return flags_.at<overflowIdx>(); }

  ABI36_0_0YGDisplay display() const { return flags_.at<displayIdx>(); }
  Flags::Ref<displayIdx> display() { return flags_.at<displayIdx>(); }

  ABI36_0_0YGFloatOptional flex() const { return flex_; }
  Ref<ABI36_0_0YGFloatOptional, &ABI36_0_0YGStyle::flex_> flex() { return {*this}; }

  ABI36_0_0YGFloatOptional flexGrow() const { return flexGrow_; }
  Ref<ABI36_0_0YGFloatOptional, &ABI36_0_0YGStyle::flexGrow_> flexGrow() { return {*this}; }

  ABI36_0_0YGFloatOptional flexShrink() const { return flexShrink_; }
  Ref<ABI36_0_0YGFloatOptional, &ABI36_0_0YGStyle::flexShrink_> flexShrink() { return {*this}; }

  CompactValue flexBasis() const { return flexBasis_; }
  Ref<CompactValue, &ABI36_0_0YGStyle::flexBasis_> flexBasis() { return {*this}; }

  const Edges& margin() const { return margin_; }
  IdxRef<ABI36_0_0YGEdge, &ABI36_0_0YGStyle::margin_> margin() { return {*this}; }

  const Edges& position() const { return position_; }
  IdxRef<ABI36_0_0YGEdge, &ABI36_0_0YGStyle::position_> position() { return {*this}; }

  const Edges& padding() const { return padding_; }
  IdxRef<ABI36_0_0YGEdge, &ABI36_0_0YGStyle::padding_> padding() { return {*this}; }

  const Edges& border() const { return border_; }
  IdxRef<ABI36_0_0YGEdge, &ABI36_0_0YGStyle::border_> border() { return {*this}; }

  const Dimensions& dimensions() const { return dimensions_; }
  IdxRef<ABI36_0_0YGDimension, &ABI36_0_0YGStyle::dimensions_> dimensions() { return {*this}; }

  const Dimensions& minDimensions() const { return minDimensions_; }
  IdxRef<ABI36_0_0YGDimension, &ABI36_0_0YGStyle::minDimensions_> minDimensions() {
    return {*this};
  }

  const Dimensions& maxDimensions() const { return maxDimensions_; }
  IdxRef<ABI36_0_0YGDimension, &ABI36_0_0YGStyle::maxDimensions_> maxDimensions() {
    return {*this};
  }

  // Yoga specific properties, not compatible with flexbox specification
  ABI36_0_0YGFloatOptional aspectRatio() const { return aspectRatio_; }
  Ref<ABI36_0_0YGFloatOptional, &ABI36_0_0YGStyle::aspectRatio_> aspectRatio() { return {*this}; }
};

bool operator==(const ABI36_0_0YGStyle& lhs, const ABI36_0_0YGStyle& rhs);
inline bool operator!=(const ABI36_0_0YGStyle& lhs, const ABI36_0_0YGStyle& rhs) {
  return !(lhs == rhs);
}
