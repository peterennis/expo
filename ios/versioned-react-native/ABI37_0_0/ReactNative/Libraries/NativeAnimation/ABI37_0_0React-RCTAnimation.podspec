# coding: utf-8
# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

require "json"

package = JSON.parse(File.read(File.join(__dir__, "..", "..", "package.json")))
version = package['version']



Pod::Spec.new do |s|
  s.name                   = "ABI37_0_0React-RCTAnimation"
  s.version                = version
  s.summary                = "A native driver for the Animated API."
  s.homepage               = "http://facebook.github.io/react-native/"
  s.license                = package["license"]
  s.author                 = "Facebook, Inc. and its affiliates"
  s.platforms              = { :ios => "9.0", :tvos => "9.2" }
  s.source                 = { :path => "." }
  s.source_files           = "{Drivers/*,Nodes/*,*}.{m}"
  s.preserve_paths         = "package.json", "LICENSE", "LICENSE-docs"
  s.header_dir             = "ABI37_0_0RCTAnimation"

  s.dependency "ABI37_0_0React-Core/RCTAnimationHeaders", version
end
