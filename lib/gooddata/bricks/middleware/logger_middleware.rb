class LoggerMiddleware < GoodData::Bricks::Middleware

  def call(params)
    logger = params[:gdc_logger] = params[:gdc_logger_file].nil? ? Logger.new(STDOUT) : Logger.new(params[:gdc_logger_file])
    logger.info("Pipeline starts")

    returning(@app.call(params)) do |result|
      logger.info("Pipeline ending")
    end
  end

end