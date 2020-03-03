# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SetMasterProject < BaseAction
      DESCRIPTION = 'Set master project'

      PARAMS = define_params(self) do
        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'ADS Client'
        param :ads_client, instance_of(Type::AdsClientType), required: false

        description 'Table Name'
        param :release_table_name, instance_of(Type::StringType), required: false

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::GDDataProductType), required: false

        description 'Released master project should be used in next rollout'
        param :set_master_project, instance_of(Type::StringType), required: false
      end

      class << self
        def call(params)
          results = []
          domain_name = params.organization || params.domain
          data_product = params.data_product
          params.segments.each do |segment_in|
            version = get_latest_version(params, domain_name, data_product.data_product_id, segment_in.segment_id) + 1
            segment_in[:data_product_id] = data_product.data_product_id
            segment_in[:master_pid] = params.set_master_project
            segment_in[:version] = version
            segment_in[:timestamp] = Time.now.utc.iso8601

            results << {
              data_product_id: data_product.data_product_id,
              segment_id: segment_in.segment_id,
              version: version
            }
          end
          results
        end

        def get_latest_version(params, domain_name, data_product_id, segment_id)
          if params.ads_client
            current_master = GoodData::LCM2::Helpers.latest_master_project_from_ads(
              params.release_table_name,
              params.ads_client,
              segment_id
            )
          else
            current_master = GoodData::LCM2::Helpers.latest_master_project_from_nfs(domain_name, data_product_id, segment_id)
          end
          return 0 unless current_master

          current_master[:version].to_i
        end
      end
    end
  end
end
