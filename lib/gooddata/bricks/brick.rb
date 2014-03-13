require File.join(File.dirname(__FILE__), 'base_downloader')
require File.join(File.dirname(__FILE__), 'utils')

Dir[File.dirname(__FILE__) + '/commands/**/*_cmd.rb'].each do |file|
  require file
end

require File.join(File.dirname(__FILE__), 'middleware/middleware')

module GoodData::Bricks
  class Pipeline
    def self.prepare(pipeline)
      pipeline.reverse.reduce(nil) {|memo, app| memo.nil? ? app.new : app.new(memo)}
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
      fail "Method version should be reimplemented"
    end

    def call(params={})
      @params = params
      ""
    end

  end
  
end
