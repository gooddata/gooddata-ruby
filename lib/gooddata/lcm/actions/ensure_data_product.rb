# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class EnsureDataProduct < BaseAction
      DESCRIPTION = 'Creates the DataProduct if it does not exist yet'

      PARAMS = define_params(self) do
        description 'client to connect to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'DataProduct to ensure'
        param :data_product, instance_of(Type::StringType), required: false

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'Logger'
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
            begin
              data_product = domain.data_products(params.data_product)
            rescue RestClient::BadRequest
              params.gdc_logger.info "Can not find DataProduct #{params.data_product}, creating it instead"
              data_product = domain.create_data_product(id: params.data_product)
            end
          end

          {
            results: [
              {
                data_product: data_product
              }
            ]
          }
        end
      end
    end
  end
end
