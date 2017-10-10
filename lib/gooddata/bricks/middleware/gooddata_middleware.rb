# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_middleware'

module GoodData
  module Bricks
    # Connects to platform and enriches parameters with GoodData::Client
    class GoodDataMiddleware < Bricks::Middleware
      DEFAULT_PROTOCOL = 'https'
      DEFAULT_HOSTNAME = 'secure.gooddata.com'

      def call(params)
        # Convert possible jruby hash to plain hash
        params = params.to_hash

        # Transform keys
        params = GoodData::Helpers.stringify_keys(params)
        # params = GoodData::Helpers.symbolize_keys(params)

        # Set logger
        logger = params['GDC_LOGGER']
        GoodData.logger = logger

        # Set parallelism
        max_concurrency = params['max_concurrency'] || params['MAX_CONCURRENCY']
        GoodData.thread_count = max_concurrency

        # Connect Client
        protocol = params['CLIENT_GDC_PROTOCOL'] || params['GDC_PROTOCOL'] || DEFAULT_PROTOCOL
        hostname = params['CLIENT_GDC_HOSTNAME'] || params['GDC_HOSTNAME'] || DEFAULT_HOSTNAME
        server = "#{protocol}://#{hostname}"
        client = GoodDataMiddleware.connect(
          server,
          params['GDC_VERIFY_SSL'].to_b,
          params['GDC_USERNAME'],
          params['GDC_PASSWORD'],
          params['GDC_SST']
        )

        opts = params['development_client']
        if opts
          if opts['server']
            server = opts['server']
          else
            protocol = opts['protocol'] || DEFAULT_PROTOCOL
            hostname = opts['hostname'] || DEFAULT_HOSTNAME
            server = "#{protocol}://#{hostname}"
          end

          development_client = GoodDataMiddleware.connect(
            server,
            opts['verify_ssl'].to_b,
            opts['username'] || opts['login'] || opts['email'],
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

        # Try to disconnect client
        begin
          client.disconnect
        rescue
          puts 'Tried to disconnect client. Was unsuccessful. Proceeding anyway.'
        end

        # Try to disconnect development_client
        begin
          development_client.disconnect if development_client != client
        rescue
          puts 'Tried to disconnect development_client. Was unsuccessful. Proceeding anyway.'
        end

        returning_value
      end

      class << self
        def connect(server, verify_ssl, username, password, sst_token) # rubocop:disable Metrics/ParameterLists
          if username.nil? || password.nil?
            puts "Connecting with SST to server #{server}"
            raise 'SST (SuperSecureToken) not present in params' if sst_token.nil?
            conn = GoodData.connect(sst_token: sst_token, server: server, verify_ssl: verify_ssl)
          else
            puts "Connecting as #{username} to server #{server}"
            conn = GoodData.connect(username, password, server: server, verify_ssl: verify_ssl)
          end
          conn.stats_on

          conn
        end
      end
    end
  end
end
