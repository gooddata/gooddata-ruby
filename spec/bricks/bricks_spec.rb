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

  describe "#load_defaults" do
    context "when you define a middleware with default_loaded_call and give it some defaults file with prefix" do
      class TestMiddleWare < GoodData::Bricks::Middleware
        def initialize(options={})
          @config = 'spec/bricks/default-config.json'
          @config_namespace = 'my__namespace'
          super(options)
        end

        def default_loaded_call(params)
          params
        end
      end

      it "puts them into params" do
        m = TestMiddleWare.new
        res = m.call({
          'config' => {
            'my' => {
              'namespace' => {
                'key' => 'redefined value',
                'new_key' => 'new value'
              }
            },
            'other_namespace' => {
              'some_key' => 'some value'
            }
          }
        })

        res.should eq({
          'config' => {
            'my' => {
              'namespace' => {
                'key' => 'redefined value',
                'new_key' => 'new value',
                'default_key' => 'default value 2'
              }
            },
            'other_namespace' => {
              'some_key' => 'some value'
            }
          }
        })
      end
    end
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
