require 'gooddata'

module GoodData::Bricks
  class RestForceMiddleware < GoodData::Bricks::Middleware

    def call(params)

      username      = params[:salesforce_username]
      password      = params[:salesforce_password]
      token         = params[:salesforce_token]
      client_id     = params[:salesforce_client_id]
      client_secret = params[:salesforce_client_secret]
      
      Restforce.log = true if params[:salesforce_client_logger]

      client = Restforce.new(
        :username       => username,
        :password       => password,
        :security_token => token,

        :client_id      => client_id,
        :client_secret  => client_secret)

      @app.call(params.merge(:salesforce_client => client))
    end

  end
end