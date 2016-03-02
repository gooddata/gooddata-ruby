# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_middleware'

module GoodData
  module Bricks
    class GoodDataMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash
        logger = params['GDC_LOGGER']
        token_name = 'GDC_SST'
        protocol_name = 'CLIENT_GDC_PROTOCOL'
        server_name = 'CLIENT_GDC_HOSTNAME'
        project_id = params['GDC_PROJECT_ID']

        server = if params[protocol_name] && params[server_name]
                   "#{params[protocol_name]}://#{params[server_name]}"
                 end

        client = if params['GDC_USERNAME'].nil? || params['GDC_PASSWORD'].nil?
                   puts "Connecting with SST to server #{server}"
                   fail 'SST (SuperSecureToken) not present in params' if params[token_name].nil?
                   GoodData.connect(sst_token: params[token_name], server: server)
                 else
                   puts "Connecting as #{params['GDC_USERNAME']} to server #{server}"
                   GoodData.connect(params['GDC_USERNAME'], params['GDC_PASSWORD'], server: server)
                 end
        project = client.projects(project_id)
        GoodData.project = project
        GoodData.logger = logger
        @app.call(params.merge('GDC_GD_CLIENT' => client, 'gdc_project' => project))
      end
    end
  end
end
