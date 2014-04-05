# encoding: UTF-8

require 'gooddata/bricks/bricks'

describe GoodData::Bricks::Brick do
  it "Has GoodData::Bricks::Brick class" do
    GoodData::Bricks::Brick.should_not == nil
  end

  describe '#version' do
    it 'Throws NotImplemented on base class' do
      brick = GoodData::Bricks::Brick.new
      expect do
        brick.version
      end.to raise_error(NotImplementedError)
    end
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
