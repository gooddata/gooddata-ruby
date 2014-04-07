# encoding: UTF-8

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/bench_middleware'

describe GoodData::Bricks::BenchMiddleware do
  it "Has GoodData::Bricks::BenchMiddleware class" do
    GoodData::Bricks::BenchMiddleware.should_not == nil
  end
end
