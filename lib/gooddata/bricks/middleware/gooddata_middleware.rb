# encoding: UTF-8

# TODO: REmove this
# require 'gooddata'

require_relative 'base_middleware'

module GoodData
  module Bricks
    class GoodDataMiddleware < Bricks::Middleware
      def call(params)
        logger = params['GDC_LOGGER']
        token_name = 'GDC_SST'
        protocol_name = 'GDC_PROTOCOL'
        server_name = 'GDC_HOSTNAME'
        project_id = params['GDC_PROJECT_ID']

        fail 'SST (SuperSecureToken) not present in params' if params[token_name].nil?

        server = if !params[protocol_name].empty? && !params[server_name].empty?
                   "#{params[protocol_name]}://#{params[server_name]}"
                 end

        client = if params['GDC_USERNAME'].nil? || params['GDC_PASSWORD'].nil?
                   GoodData.connect(sst_token: params['GDC_SST'], server: server)
                 else
                   GoodData.connect(params['GDC_USERNAME'], params['GDC_PASSWORD'], server: server)
                 end
        GoodData.logger = logger
        GoodData.with_project(project_id, :client => client) do |p|
          @app.call(params)
        end
      end
    end
  end
end
