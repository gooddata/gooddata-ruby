require 'gooddata'

module GoodData::Bricks
  class GoodDataMiddleware < GoodData::Bricks::Middleware

    def call(params)
      logger = params[:gdc_logger]
      token_name = :GDC_SST
      protocol_name = :GDC_PROTOCOL
      server_name = :GDC_SERVER
      project_id = params[:GDC_PROJECT_ID]

      fail "SST (SuperSecureToken) not present in params" if params[token_name].nil?
      logger.info "Connecting to GD with SST"
      server = if !params[protocol_name].empty? && !params[server_name].empty?
        params[protocol_name] + "://" + params[server_name]
      end

      GoodData.connect(params[:GDC_USERANME], params[:GDC_PASSWORD], {:server => server})
      GoodData.logger = logger
      GoodData.with_project(project_id) do |p|
        @app.call(params)
      end
    end

  end
end