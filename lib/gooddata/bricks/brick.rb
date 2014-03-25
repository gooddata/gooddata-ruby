# encoding: UTF-8

require_relative 'base_downloader'
require_relative 'utils'

Dir[File.dirname(__FILE__) + '/commands/**/*_cmd.rb'].each do |file|
  require file
end

require_relative 'middleware/middleware'

module GoodData::Bricks
  class Pipeline
    def self.prepare(pipeline)
      pipeline.reverse.reduce(nil) do |memo, app|
        if memo.nil?
          app.respond_to?(:new) ? (app.new) : app
        else
          app.respond_to?(:new) ? (app.new(:app => memo)) : (app.app = memo; app)
        end
      end
    end
  end

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
