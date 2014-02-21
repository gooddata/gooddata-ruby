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
      server = if !params[protocol_name].empty? && !params[server_name].empty?
        params[protocol_name] + "://" + params[server_name]
      end

      fail "GoodData username is missing. Expected param :GDC_USERANME" if params[:GDC_USERNAME].nil?
      fail "GoodData password is missing. Expected param :GDC_PASSWORD" if params[:GDC_PASSWORD].nil?

      GoodData.connect(params[:GDC_USERNAME], params[:GDC_PASSWORD], {:server => server})
      GoodData.logger = logger
      GoodData.with_project(project_id) do |p|
        @app.call(params)
      end
    end

  end
end