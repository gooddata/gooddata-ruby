require 'gooddata'

class GoodDataMiddleware < GoodData::Bricks::Middleware

  def call(params)
    logger = params[:gdc_logger]
    token_name = :gdc_sst
    fail "SST (SuperSecureToken) not present in params" if params[token_name].nil?
    logger.info "Connecting to GD with SST"
    GoodData.connect_with_sst(params[token_name])
    GoodData.logger = logger
    @app.call(params)
  end

end
