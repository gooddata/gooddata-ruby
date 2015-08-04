# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + '*.rb').each do |file|
  require_relative file
end
