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
          super(options)
        end

        def call(params)
          params = super(params)
          my_stuff = params['config']['my']['namespace']
          puts "Now I have the defaults and runtime parameters merged and loaded: #{my_stuff['key']}"

          # Doing something cool and puting it into params
          params['something_cool'] = "#{my_stuff['key']} and also #{my_stuff['default_key']}"

          @app.call(params)
        end
      end

      class TestBrick
        def call(params)
          # doing something with params
          puts "Brick: #{params['something_cool']}"
          params
        end
      end

      it "puts them into params" do
        p = GoodData::Bricks::Pipeline.prepare([
          TestMiddleWare,
          TestBrick
        ])

        res = p.call({
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
          },
          "something_cool" => "redefined value and also default value 2"
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
