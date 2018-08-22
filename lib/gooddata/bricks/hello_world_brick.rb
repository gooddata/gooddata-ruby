require_relative 'brick'

module GoodData
  module Bricks
    # Simple brick used for testing and debug purposes
    class HelloWorldBrick < GoodData::Bricks::Brick
      def version
        '0.0.1'
      end

      # HelloWorld brick entry-point
      #
      # @param [Hash] params Parameters
      # @option [String] 'message' text to be returned in result, if nill - nothing is returned
      # :reek:UtilityFunction
      def call(params)
        GoodData::LCM2.perform('hello_world', params)
      end
    end
  end
end
