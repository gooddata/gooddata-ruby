# encoding: UTF-8

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/stdout_middleware'

  describe GoodData::Bricks::STDOUTLoggingMiddleware do
  it "Has GoodData::Bricks::STDOUTLoggingMiddleware class" do
    GoodData::Bricks::STDOUTLoggingMiddleware.should_not == nil
  end
end
