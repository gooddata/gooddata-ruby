# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/bench_middleware'

describe GoodData::Bricks::BenchMiddleware do
  it "Has GoodData::Bricks::BenchMiddleware class" do
    GoodData::Bricks::BenchMiddleware.should_not == nil
  end
end
