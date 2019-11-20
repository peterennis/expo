/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <cassert>
#include <string>

#include <folly/Optional.h>
#include <ABI36_0_0jsi/ABI36_0_0jsi.h>

#include <ABI36_0_0ReactCommon/ABI36_0_0JSCallInvoker.h>

using namespace ABI36_0_0facebook;

namespace ABI36_0_0facebook {
namespace ABI36_0_0React {

jsi::Object deepCopyJSIObject(jsi::Runtime &rt, const jsi::Object &obj);
jsi::Array deepCopyJSIArray(jsi::Runtime &rt, const jsi::Array &arr);

struct Promise {
  Promise(jsi::Runtime &rt, jsi::Function resolve, jsi::Function reject);

  void resolve(const jsi::Value &result);
  void reject(const std::string &error);

  jsi::Runtime &runtime_;
  jsi::Function resolve_;
  jsi::Function reject_;
};

using PromiseSetupFunctionType =
    std::function<void(jsi::Runtime &rt, std::shared_ptr<Promise>)>;
jsi::Value createPromiseAsJSIValue(
    jsi::Runtime &rt,
    const PromiseSetupFunctionType func);

// Helper for passing jsi::Function arg to other methods.
class CallbackWrapper {
 private:
  struct Data {
    Data(
        jsi::Function callback,
        jsi::Runtime &runtime,
        std::shared_ptr<ABI36_0_0React::JSCallInvoker> jsInvoker)
        : callback(std::move(callback)),
          runtime(runtime),
          jsInvoker(std::move(jsInvoker)) {}

    jsi::Function callback;
    jsi::Runtime &runtime;
    std::shared_ptr<ABI36_0_0React::JSCallInvoker> jsInvoker;
  };

  folly::Optional<Data> data_;

 public:
  CallbackWrapper(
      jsi::Function callback,
      jsi::Runtime &runtime,
      std::shared_ptr<ABI36_0_0React::JSCallInvoker> jsInvoker)
      : data_(Data{std::move(callback), runtime, jsInvoker}) {}

  // Delete the enclosed jsi::Function
  void destroy() {
    data_ = folly::none;
  }

  bool isDestroyed() {
    return !data_.hasValue();
  }

  jsi::Function &callback() {
    assert(!isDestroyed());
    return data_->callback;
  }

  jsi::Runtime &runtime() {
    assert(!isDestroyed());
    return data_->runtime;
  }

  ABI36_0_0React::JSCallInvoker &jsInvoker() {
    assert(!isDestroyed());
    return *(data_->jsInvoker);
  }
};

} // namespace ABI36_0_0React
} // namespace ABI36_0_0facebook
