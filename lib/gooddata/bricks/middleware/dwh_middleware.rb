# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_middleware'

require 'gooddata_datawarehouse' if RUBY_PLATFORM == 'java'

module GoodData
  module Bricks
    class WarehouseMiddleware < Bricks::Middleware
      def call(params)
        if params.key?('ads_client') && (RUBY_PLATFORM == 'java')
          GoodData.logger.info "Setting up ADS connection to #{params['ads_client']['ads_id'] || params['ads_client']['jdbc_url']}"
          raise "ADS middleware needs username either as part of ads_client spec or as a global 'GDC_USERNAME' parameter" unless params['ads_client']['username'] || params['GDC_USERNAME']
          raise "ADS middleware needs password either as part of ads_client spec or as a global 'GDC_PASSWORD' parameter" unless params['ads_client']['password'] || params['GDC_PASSWORD']

          ads = GoodData::Datawarehouse.new(params['ads_client']['username'] || params['GDC_USERNAME'], params['ads_client']['password'] || params['GDC_PASSWORD'], params['ads_client']['ads_id'], jdbc_url: params['ads_client']['jdbc_url'])
          @app.call(params.merge('ads_client' => ads, :ads_client => ads))
        else
          @app.call(params)
        end
      end
    end
  end
end
