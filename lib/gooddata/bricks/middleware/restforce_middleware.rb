# encoding: UTF-8

# TODO: Remove this
# require 'gooddata'

require_relative 'base_middleware'

module GoodData
  module Bricks
    class RestForceMiddleware < Bricks::Middleware
      DEFAULT_VERSION = '29.0'

      def self.create_client(params)
        downloader_config = params['config']['downloader']['salesforce']
        username = downloader_config['username']
        password = downloader_config['password']
        token = downloader_config['token']
        client_id = downloader_config['client_id']
        client_secret = downloader_config['client_secret']
        oauth_refresh_token = downloader_config['oauth_refresh_token']
        host = downloader_config['host']
        version = downloader_config['api_version'] || DEFAULT_VERSION

        credentials = if username && password && token
                        {
                          :username => username,
                          :password => password,
                          :security_token => token
                        }
                      elsif (oauth_refresh_token) && (!oauth_refresh_token.empty?)
                        {
                          :refresh_token => oauth_refresh_token
                        }
                      end

        client = if credentials
                   credentials.merge!(
                     :client_id => client_id,
                     :client_secret => client_secret
                   )
                   credentials[:host] = host unless host.nil?
                   credentials[:api_version] = version

                   Restforce.log = true if params['GDC_LOGGER']

                   Restforce.new(credentials)
                 end
        params.merge('salesforce_client' => client)
      end

      def call(params)
        params = self.class.create_client(params)
        @app.call(params)
      end
    end
  end
end
