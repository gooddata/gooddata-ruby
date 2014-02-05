require 'gooddata'

module GoodData::Bricks
  class RestForceMiddleware < GoodData::Bricks::Middleware

    def call(params)

      username      = params[:salesforce_username]
      password      = params[:salesforce_password]
      token         = params[:salesforce_token]
      client_id     = params[:salesforce_client_id]
      client_secret = params[:salesforce_client_secret]
      oauth_token   = params[:salesforce_oauth_token]
      refresh_token = params[:salesforce_refresh_token]
      host          = params[:salesforce_host]

      credentials = {}

      credentials = if (username && password && token)
        {
          :username       => username,
          :password       => password,
          :security_token => token
        }
      elsif (oauth_token && refresh_token)
        {
          :oauth_token    => oauth_token,
          :refresh_token  => refresh_token
        }
      else
        fail "Salesforce middleware failed while trying to log in. Either salesforce_username, salesforce_password, salesforce_token or salesforce_oauth_token, salesforce_refresh_token are needed. Additionally you have to specify salesforce_client_id and salesforce_client_secret parameters in both cases"
      end


      credentials.merge!({
        :client_id      => client_id,
        :client_secret  => client_secret,
      })
      credentials[:host] = host unless host.nil?

      Restforce.log = true if params[:salesforce_client_logger]
      client = Restforce.new(credentials)
      @app.call(params.merge(:salesforce_client => client))
    end

  end
end