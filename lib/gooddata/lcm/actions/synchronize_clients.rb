# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeClients < BaseAction
      DESCRIPTION = 'Synchronize LCM Clients'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::GDDataProductType), required: false

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'Table Name'
        param :release_table_name, instance_of(Type::StringType), required: false

        description 'ADS Client'
        param :ads_client, instance_of(Type::AdsClientType), required: true

        description 'Additional Hidden Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false
      end

      RESULT_HEADER = [
        :segment,
        :successful_count,
        :master_name,
        :master_pid
      ]

      DEFAULT_TABLE_NAME = 'LCM_RELEASE'

      class << self
        def call(params)
          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          fail "Either organisation or domain has to be specified in params" unless domain_name
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")
          data_product = params.data_product
          domain_segments = domain.segments(:all, data_product)

          segments = params.segments.map do |seg|
            domain_segments.find do |s|
              s.segment_id == seg.segment_id
            end
          end

          results = segments.map do |segment|
            replacements = {
              table_name: params.release_table_name || DEFAULT_TABLE_NAME,
              segment_id: segment.segment_id
            }

            path = File.expand_path('../../data/select_from_lcm_release.sql.erb', __FILE__)
            query = GoodData::Helpers::ErbHelper.template_file(path, replacements)

            res = params.ads_client.execute_select(query)
            sorted = res.sort_by { |row| row[:version] }
            current_master = sorted.last[:master_project_id]

            # TODO: Check res.first.nil? || res.first[:master_project_id].nil?
            master = client.projects(current_master)

            segment.master_project = master
            segment.save

            res = segment.synchronize_clients

            sync_result = res.json['synchronizationResult']
            failed_count = sync_result['failedClients']['count']

            if failed_count.to_i > 0
              fail("#{failed_count} clients failed to synchronize. " \
                   "Details: #{sync_result['links']['details']}")
            end

            {
              segment: segment.id,
              master_pid: master.pid,
              master_name: master.title,
              successful_count: sync_result['successfulClients']['count']
            }
          end

          # Return results
          results
        end
      end
    end
  end
end
