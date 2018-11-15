require_relative 'brick'

module GoodData
  module Bricks
    # Simple brick used for printing help message about bricks
    class HelpBrick < GoodData::Bricks::Brick
      def version
        '0.0.1'
      end

      # Help brick entry-point
      def call(params)
        GoodData::LCM2.perform('help', params)
      end
    end
  end
end
