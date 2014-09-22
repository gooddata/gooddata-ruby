# encoding: UTF-8

require 'salesforce_bulk_query'

require_relative 'base_middleware'

module GoodData
  module Bricks
    class BulkSalesforceMiddleware < Bricks::Middleware
      DEFAULT_VERSION = '29.0'

      def self.create_client(params)
        salesforce = nil
        if params['salesforce_client']

          client = params['salesforce_client']
          client.authenticate!

          salesforce = SalesforceBulkQuery::Api.new(client, :logger => params['GDC_LOGGER'])
          # SalesforceBulkQuery adds its own Restforce logging so turn it off
          Restforce.log = false if params['GDC_LOGGER']
        end
        params.merge('salesforce_bulk_client' => salesforce)
      end

      def call(params)
        params = self.class.create_client(params)
        @app.call(params)
      end
    end
  end
end
