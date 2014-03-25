# encoding: UTF-8

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/logger_middleware'

describe GoodData::Bricks::LoggerMiddleware do
  it "Has GoodData::Bricks::LoggerMiddleware class" do
    GoodData::Bricks::LoggerMiddleware.should_not == nil
  end
end
