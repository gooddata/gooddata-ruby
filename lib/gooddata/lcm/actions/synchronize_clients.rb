# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
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

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: true
      end

      RESULT_HEADER = [
        :segment,
        :successful_count,
        :failed_count,
        :master_name,
        :master_pid,
        # :details
      ]

      DEFAULT_QUERY_SELECT = 'SELECT segment_id, master_project_id, version from lcm_release WHERE segment_id=\'#{segment_id}\';'

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")
          domain_segments = domain.segments

          segments = params.segments.map do |seg|
            domain_segments.find do |s|
              s.segment_id == seg.segment_id
            end
          end

          results = segments.map do |segment|
            res = params.ads_client.execute_select(DEFAULT_QUERY_SELECT.gsub('#{segment_id}', segment.segment_id))

            # TODO: Check res.first.nil? || res.first[:master_project_id].nil?
            master = client.projects(res.first[:master_project_id])

            segment.master_project = master
            segment.save

            res = segment.synchronize_clients

            sync_result = res.json['synchronizationResult']

            {
              segment: segment.id,
              master_pid: master.pid,
              master_name: master.title,
              successful_count: sync_result['successfulClients']['count'],
              failed_count: sync_result['failedClients']['count'],
              # details: sync_result['links']['details']
            }
          end

          # Return results
          results
        end
      end
    end
  end
end