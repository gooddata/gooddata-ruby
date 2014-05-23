# encoding: UTF-8

require 'gooddata'

require_relative 'base_middleware'

module GoodData
  module Bricks
    class RestForceMiddleware < Bricks::Middleware
      DEFAULT_VERSION = '29.0'

      def call(params)
        username = params["salesforce_username"]
        password = params["salesforce_password"]
        token = params["salesforce_token"]
        client_id = params["salesforce_client_id"]
        client_secret = params["salesforce_client_secret"]
        oauth_refresh_token = params["salesforce_oauth_refresh_token"]
        host = params["salesforce_host"]
        version = params["salesforce_api_version"] || DEFAULT_VERSION

        credentials = if (username && password && token)
                        {
                          :username => username,
                          :password => password,
                          :security_token => token
                        }
                      elsif (oauth_refresh_token) && (!oauth_refresh_token.empty?)
                        {
                          :refresh_token => oauth_refresh_token,
                        }
                      end

        client = if credentials
                   credentials.merge!({
                                        :client_id => client_id,
                                        :client_secret => client_secret,
                                      })
                   credentials[:host] = host unless host.nil?
                   credentials[:api_version] = version

                   Restforce.log = true if params["salesforce_client_logger"]

                   Restforce.new(credentials)
                 end
        @app.call(params.merge("salesforce_client" => client))
      end
    end
  end
end
