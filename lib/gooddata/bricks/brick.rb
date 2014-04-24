# encoding: UTF-8

require_relative 'base_downloader'
require_relative 'utils'

require_relative 'middleware/middleware'

module GoodData
  module Bricks
    # Brick base class
    class Brick
      def log(message)
        logger = @params[:gdc_logger]
        logger.info(message) unless logger.nil?
      end

      # Name of the brick
      def name
        self.class
      end

      # Version of brick, this should be implemented in subclasses
      def version
        fail NotImplementedError, 'Method version should be reimplemented'
      end

      # Bricks implementation which can be 'called'
      def call(params = {})
        @params = params
        ''
      end
    end
  end
end
