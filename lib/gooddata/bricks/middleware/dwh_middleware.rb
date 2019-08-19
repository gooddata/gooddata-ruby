# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_middleware'

require 'gooddata_datawarehouse' if RUBY_PLATFORM == 'java'

module GoodData
  module Bricks
    # Connects to the warehouse (ADS) and enriches parameters with GoodData::Datawarehouse
    class WarehouseMiddleware < Bricks::Middleware
      def call(params)
        if params.key?('ads_client')
          GoodData.logger.info "Setting up ADS connection to #{params['ads_client']['ads_id'] || params['ads_client']['jdbc_url']}"

          username = params['ads_client']['username'] || params['GDC_USERNAME']
          password = params['ads_client']['password'] || params['GDC_PASSWORD']
          instance_id = params['ads_client']['ads_id']
          jdbc_url = params['ads_client']['jdbc_url']
          sst_token = params['ads_client']['sst'] || params['GDC_SST']

          ads = if username.nil? || password.nil?
                  GoodData.logger.info 'Using SST for ADS connection'
                  GoodData::Datawarehouse.new_instance(
                    instance_id: instance_id,
                    jdbc_url: jdbc_url,
                    sst: sst_token
                  )
                else
                  GoodData::Datawarehouse.new(
                    username,
                    password,
                    instance_id,
                    jdbc_url: jdbc_url
                  )
                end
          @app.call(params.merge('ads_client' => ads, :ads_client => ads))
        else
          @app.call(params)
        end
      end
    end
  end
end
