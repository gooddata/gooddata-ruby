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

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'DataLogger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true
      end

      RESULT_HEADER = [
        :data_product
      ]

      class << self
        def call(params)
          params = params.to_hash
          client = params.gdc_gd_client
          domain_name = params.organization || params.domain
          fail "Either organisation or domain has to be specified in params" unless domain_name
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          if params.key?(:data_product)
            data_product_id = params.data_product
          else
            params.gdc_logger.info "Using data product 'default' since none was specified in brick parameters"
            data_product_id = 'default'
          end
          data_product = domain.data_products(data_product_id)
          results = [
            {
              data_product: data_product_id
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
