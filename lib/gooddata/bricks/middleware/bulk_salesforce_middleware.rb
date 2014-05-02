# encoding: UTF-8

require 'salesforce_bulk'

require_relative 'base_middleware'

module GoodData
  module Bricks
    class BulkSalesforceMiddleware < Bricks::Middleware
      def call(params)
        username = params[:salesforce_username]
        password = params[:salesforce_password]
        token = params[:salesforce_token]
        client_id = params[:salesforce_client_id]
        client_secret = params[:salesforce_client_secret]
        host = params[:salesforce_host]

        credentials = if username && password && token
          {
            :username => username,
            :password => password,
            :security_token => token
          }
        end

        client = if credentials
          credentials.merge!(
            :client_id => client_id,
            :client_secret => client_secret
          )
          credentials[:host] = host unless host.nil?
          SalesforceBulk::Api.new(credentials[:username], credentials[:password] + credentials[:security_token])
        end
        @app.call(params.merge(:salesforce_bulk_client => client))
      end
    end
  end
end
