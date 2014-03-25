# encoding: UTF-8

require 'gooddata/bricks/bricks'

describe GoodData::Bricks::Brick do
  it "Has GoodData::Bricks::Brick class" do
    GoodData::Bricks::Brick.should_not == nil
  end

  it "should be possible to execute custom brick" do
    class CustomBrick < GoodData::Bricks::Brick

      def call(params)
        puts 'hello'
      end
    end

    p = GoodData::Bricks::Pipeline.prepare([CustomBrick])

    p.call({})
  end
end
