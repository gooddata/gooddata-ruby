# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/gooddata_middleware'

describe GoodData::Bricks::GoodDataMiddleware do
  it "Has GoodData::Bricks::GoodDataMiddleware class" do
    expect(GoodData::Bricks::GoodDataMiddleware).not_to be_nil
  end
end
