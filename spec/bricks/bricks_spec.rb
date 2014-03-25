# encoding: UTF-8

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/base_middleware'
require 'pry'

describe GoodData::Bricks do
  it "Has GoodData::Bricks::Brick class" do
    GoodData::Bricks::Brick.should_not == nil
  end

  it "should be possible to use block as an app in pipeline" do
    p = GoodData::Bricks::Pipeline.prepare([
      lambda { |params| puts "x" }
    ])
    p.call({})
  end


  # TODO: Better test pre and post so we are sure it is executed in right order
  it "should be possible to use instance both as middleware and app" do

    class DummyMiddleware < GoodData::Bricks::Middleware

      def call(params)
        puts "pre"
        app.call(params)
        puts "post"
      end

    end

    p = GoodData::Bricks::Pipeline.prepare([
      DummyMiddleware.new,
      lambda { |params| puts "x" }
    ])
    p.call({})
  end

end
