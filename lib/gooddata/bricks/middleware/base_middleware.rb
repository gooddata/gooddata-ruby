# encoding: UTF-8

module GoodData
  module Bricks
    class Middleware
      attr_accessor :app

      include Bricks::Utils

      def initialize(options = {})
        @app = options[:app]
      end
    end
  end
end
