# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_middleware'

module GoodData
  module Bricks
    class RestForceMiddleware < Bricks::Middleware
      DEFAULT_VERSION = '29.0'.freeze

      def self.prepare_credentials(downloader_config)
        username = downloader_config['username']
        password = downloader_config['password']
        token = downloader_config['token']
        oauth_refresh_token = downloader_config['oauth_refresh_token']

        if username && password && token
          {
            username: username,
            password: password,
            security_token: token
          }
        elsif oauth_refresh_token && !oauth_refresh_token.empty?
          {
            refresh_token: oauth_refresh_token
          }
        end
      end

      def self.create_client(params)
        downloader_config = params['config']['downloader']['salesforce']
        credentials = prepare_credentials(params)

        client = if credentials
                   credentials[:client_id] = downloader_config['client_id']
                   credentials[:client_secret] = downloader_config['client_secret']

                   host = downloader_config['host']
                   credentials[:host] = host if host
                   credentials[:api_version] = downloader_config['api_version'] || DEFAULT_VERSION

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
