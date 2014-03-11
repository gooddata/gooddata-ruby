require 'gooddata/bricks/utils'
require 'gooddata/bricks/base_downloader'
require 'gooddata/bricks/middleware/middleware'
require 'gooddata/bricks/middleware/bench_middleware'
require 'gooddata/bricks/middleware/gooddata_middleware'
require 'gooddata/bricks/middleware/logger_middleware'
require 'gooddata/bricks/middleware/stdout_middleware'
require 'gooddata/bricks/middleware/restforce_middleware'
require 'gooddata/bricks/middleware/bulk_salesforce_middleware.rb'
require 'gooddata/bricks/middleware/twitter_middleware'

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
