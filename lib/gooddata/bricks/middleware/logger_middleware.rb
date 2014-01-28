require 'logger'

module GoodData::Bricks
  class LoggerMiddleware < GoodData::Bricks::Middleware

    def call(params)
      logger = params[:gdc_logger] = params[:GDC_LOGGER_FILE].nil? ? Logger.new(STDOUT) : Logger.new(params[:GDC_LOGGER_FILE])
      logger.info("Pipeline starts")

      returning(@app.call(params)) do |result|
        logger.info("Pipeline ending")
      end
    end

  end
end