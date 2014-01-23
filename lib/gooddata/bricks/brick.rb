module GoodData
  module Bricks

    class Pipeline
      def self.prepare(pipeline)
        pipeline.reverse.reduce(nil) {|memo, app| memo.nil? ? app.new : app.new(memo)}
      end
    end

    class Middleware
      include GoodData::Bricks::Utils

      def initialize(app)
        @app = app
      end
      
    end
    
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
end
