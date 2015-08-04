# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/core/core'

describe GoodData::NilLogger do
  it "Has GoodData::NilLogger class" do
    GoodData::NilLogger.should_not be(nil)
  end
end