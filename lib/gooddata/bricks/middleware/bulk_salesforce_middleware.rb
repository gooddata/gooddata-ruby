# encoding: UTF-8

require 'salesforce_bulk_query'

require_relative 'base_middleware'

module GoodData
  module Bricks
    class BulkSalesforceMiddleware < Bricks::Middleware
      DEFAULT_VERSION = '29.0'

      def call(params)
        username = params["salesforce_username"]
        password = params["salesforce_password"]
        token = params["salesforce_token"]
        oauth_refresh_token = params["salesforce_oauth_refresh_token"]

        client_id = params["salesforce_client_id"]
        client_secret = params["salesforce_client_secret"]
        host = params["salesforce_host"]
        version = params["salesforce_api_version"] || DEFAULT_VERSION

        app_info = {
          :client_id => client_id,
          :client_secret => client_secret,
        }
        app_info[:host] = host unless host.nil?
        salesforce = nil
        client_params = nil

        if (username && password && token)
          # use basic auth
          client_params = {
            :username => username,
            :password => password,
            :security_token => token
          }.merge(app_info)

        elsif (oauth_refresh_token)
          # use oauth
          client_params = {
            :refresh_token => oauth_refresh_token,
          }.merge(app_info)
        end

        if client_params

          client_params[:api_version] = version

          client = params["salesforce_client"] || Restforce.new(client_params)
          client.authenticate!

          salesforce = SalesforceBulkQuery::Api.new(client, :logger => params["GDC_LOGGER"])
          # SalesforceBulkQuery adds its own Restforce logging so turn it off
          Restforce.log = false if params["GDC_LOGGER"]
        end

        @app.call(params.merge("salesforce_bulk_client" => salesforce))
      end
    end
  end
end
