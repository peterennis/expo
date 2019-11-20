/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include "ABI36_0_0LongLivedObject.h"

namespace ABI36_0_0facebook {
namespace ABI36_0_0React {

// LongLivedObjectCollection
LongLivedObjectCollection &LongLivedObjectCollection::get() {
  static LongLivedObjectCollection instance;
  return instance;
}

LongLivedObjectCollection::LongLivedObjectCollection() {}

void LongLivedObjectCollection::add(std::shared_ptr<LongLivedObject> so) {
  collection_.insert(so);
}

void LongLivedObjectCollection::remove(const LongLivedObject *o) {
  auto p = collection_.begin();
  for (; p != collection_.end(); p++) {
    if (p->get() == o) {
      break;
    }
  }
  if (p != collection_.end()) {
    collection_.erase(p);
  }
}

void LongLivedObjectCollection::clear() {
  collection_.clear();
}

// LongLivedObject
LongLivedObject::LongLivedObject() {}

void LongLivedObject::allowRelease() {
  LongLivedObjectCollection::get().remove(this);
}

} // namespace ABI36_0_0React
} // namespace ABI36_0_0facebook
