# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_middleware'

module GoodData
  module Bricks
    class GoodDataMiddleware < Bricks::Middleware
      DEFAULT_PROTOCOL = 'https'
      DEFAULT_HOSTNAME = 'secure.gooddata.com'

      def call(params)
        # Convert possible jruby hash to plain hash
        params = params.to_hash

        # Transform keys
        params = GoodData::Helpers.deep_stringify_keys(params)
        # params = GoodData::Helpers.deep_symbolize_keys(params)

        # Set logger
        logger = params['GDC_LOGGER']
        GoodData.logger = logger

        # Connect Client
        client = GoodDataMiddleware.connect(
          params['CLIENT_GDC_PROTOCOL'] || DEFAULT_PROTOCOL,
          params['CLIENT_GDC_HOSTNAME'] || DEFAULT_HOSTNAME,
          params['GDC_VERIFY_SSL'].to_b,
          params['GDC_USERNAME'],
          params['GDC_PASSWORD'],
          params['GDC_SST']
        )

        opts = params['development_client']
        if opts
          development_client = GoodDataMiddleware.connect(
            opts['protocol'] || DEFAULT_PROTOCOL,
            opts['hostname'] || DEFAULT_HOSTNAME,
            opts['verify_ssl'].to_b,
            opts['username'],
            opts['password'],
            opts['sst']
          )
        else
          development_client = client
        end

        new_params = {
          'GDC_GD_CLIENT' => client,
          'development_client' => development_client
        }

        if params['GDC_PROJECT_ID']
          new_params['gdc_project'] = GoodData.project = client.projects(params['GDC_PROJECT_ID'])
        end

        returning_value = @app.call(params.merge(new_params))
        begin
          client.disconnect
        rescue
          puts 'Tried to disconnect. Was unsuccessful. Proceeding anyway.'
        end
        returning_value
      end

      class << self
        def connect(protocol, hostname, verify_ssl, username, password, sst_token)
          server = "#{protocol}://#{hostname}" if protocol && hostname

          if username.nil? || password.nil?
            puts "Connecting with SST to server #{server}"
            raise 'SST (SuperSecureToken) not present in params' if sst_token.nil?
            GoodData.connect(sst_token: sst_token, server: server, verify_ssl: verify_ssl)
          else
            puts "Connecting as #{username} to server #{server}"
            GoodData.connect(username, password, server: server, verify_ssl: verify_ssl)
          end
        end
      end
    end
  end
end
