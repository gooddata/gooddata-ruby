# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class CollectDataProduct < BaseAction
      DESCRIPTION = 'Collect DataProduct to be used in the actions'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::StringType), required: false
      end

      RESULT_HEADER = [
        :data_product
      ]

      class << self
        def call(params)
          params = params.to_hash
          client = params.gdc_gd_client
          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          if params.key?(:data_product)
            begin
              data_product = domain.data_products(params.data_product)
            rescue RestClient::BadRequest
              fail 'the specified DataProduct does not exist'
            end
          else
            params.gdc_logger.info 'Please specify the data_product parameter when using the brick - trying to find a fallback'
            data_products = domain.data_products(:all)
            fail 'No data_product parameter specified - unable to fallback to a default' if data_products.length > 1 || data_products.empty?
            data_product = data_products.first
          end

          results = [
            {
              data_product: data_product
            }
          ]

          {
            results: results,
            params: {
              data_product: data_product
            }
          }
        end
      end
    end
  end
end
