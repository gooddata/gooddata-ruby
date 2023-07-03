# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/restforce_middleware'

describe GoodData::Bricks::RestForceMiddleware do
  it "Has GoodData::Bricks::RestForceMiddleware class" do
    expect(GoodData::Bricks::RestForceMiddleware).not_to be_nil
  end
end
