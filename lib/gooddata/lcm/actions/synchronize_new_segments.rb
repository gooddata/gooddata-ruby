# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeNewSegments < BaseAction
      DESCRIPTION = 'Synchronize New Segments'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::GdProductType), required: false

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'Additional Hidden Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false
      end

      class << self
        def call(params)
          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          fail "Either organisation or domain has to be specified in params" unless domain_name
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")
          data_product = params.data_product
          domain_segments = domain.segments(:all, data_product)

          params.segments.pmap do |segment_in|
            segment_id = segment_in.segment_id

            segment = domain_segments.find do |ds|
              ds.segment_id == segment_id
            end

            if segment_in.is_new
              segment.synchronize_clients

              {
                segment: segment_id,
                new: true,
                synchronized: true
              }
            else
              {
                segment: segment_id,
                new: false,
                synchronized: false
              }
            end
          end
        end
      end
    end
  end
end
