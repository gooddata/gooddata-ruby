# encoding: UTF-8

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/gooddata_middleware'

describe GoodData::Bricks::GoodDataMiddleware do
  it "Has GoodData::Bricks::GoodDataMiddleware class" do
    GoodData::Bricks::GoodDataMiddleware.should_not == nil
  end
end
