require 'gooddata'

class GoodDataMiddleware < GoodData::Bricks::Middleware

  def call(params)
    logger = params[:gdc_logger]
    token_name = :GDC_SST
    protocol_name = :GDC_PROTOCOL
    server_name = :GDC_SERVER

    fail "SST (SuperSecureToken) not present in params" if params[token_name].nil?
    logger.info "Connecting to GD with SST"
    server = if !params[protocol_name].empty? && !params[server_name].empty?
      params[protocol_name] + "://" + params[server_name]
    end

    GoodData.connect_with_sst(params[token_name], {:server => server})
    GoodData.logger = logger
    @app.call(params)
  end

end
