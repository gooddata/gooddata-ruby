# encoding: UTF-8

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/twitter_middleware'

  describe GoodData::Bricks::TwitterMiddleware do
  it "Has GoodData::Bricks::TwitterMiddleware class" do
    GoodData::Bricks::TwitterMiddleware.should_not == nil
  end
end
