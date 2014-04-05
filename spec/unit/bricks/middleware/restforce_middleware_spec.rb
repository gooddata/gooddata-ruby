# encoding: UTF-8

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/restforce_middleware'

  describe GoodData::Bricks::RestForceMiddleware do
  it "Has GoodData::Bricks::RestForceMiddleware class" do
    GoodData::Bricks::RestForceMiddleware.should_not == nil
  end
end
