# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/core/core'

describe GoodData::NilLogger do
  it "Has GoodData::NilLogger class" do
    expect(GoodData::NilLogger).not_to be_nil
  end
end
