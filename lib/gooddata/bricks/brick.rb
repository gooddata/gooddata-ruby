# encoding: UTF-8

require_relative 'base_downloader'
require_relative 'utils'

require_relative 'middleware/middleware'

module GoodData::Bricks
  # Brick base class
  class Brick
    def log(message)
      logger = @params[:gdc_logger]
      logger.info(message) unless logger.nil?
    end

    def name
      self.class
    end

    def version
      fail 'Method version should be reimplemented'
    end

    def call(params={})
      @params = params
      ''
    end
  end
end
