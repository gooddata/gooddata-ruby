require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/middleware'

describe GoodData::Bricks do
  it "Has GoodData::Bricks::Brick class" do
    GoodData::Bricks::Brick.should_not == nil
  end

  it "should be possible to execute a brick" do

    class DummyBrick < GoodData::Bricks::Brick

      def call(params)
        puts "hello"
      end
    end

    include GoodData::Bricks

    p = GoodData::Bricks::Pipeline.prepare([GoodData::Bricks::BenchMiddleware, DummyBrick])

    p.call({})
  end
end
