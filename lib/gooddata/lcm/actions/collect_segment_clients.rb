# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class CollectSegmentClients < BaseAction
      DESCRIPTION = 'Collect Clients'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: true

        description 'ADS Client'
        param :ads_client, instance_of(Type::AdsClientType), required: true

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'Table Name'
        param :release_table_name, instance_of(Type::StringType), required: false
      end

      RESULT_HEADER = [
        :from_name,
        :from_pid,
        :to_name,
        :to_pid
      ]

      DEFAULT_TABLE_NAME = 'LCM_RELEASE'

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

          results = []
          synchronize_clients = segments.map do |segment|
            replacements = {
              table_name: params.release_table_name || DEFAULT_TABLE_NAME,
              segment_id: segment.segment_id
            }

            path = File.expand_path('../../data/select_from_lcm_release.sql.erb', __FILE__)
            query = GoodData::Helpers::ErbHelper.template_file(path, replacements)

            res = params.ads_client.execute_select(query)

            # TODO: Check res.first.nil? || res.first[:master_project_id].nil?
            master = client.projects(res.first[:master_project_id])
            master_pid = master.pid
            master_name = master.title

            sync_info = {
              segment_id: segment.segment_id,
              from: master_pid,
              to: segment.clients.map do |segment_client|
                client_project = segment_client.project
                to_pid = client_project.pid
                results << {
                  from_name: master_name,
                  from_pid: master_pid,
                  to_name: client_project.title,
                  to_pid: to_pid
                }

                {
                  pid: to_pid,
                  client_id: segment_client.client_id
                }
              end
            }

            sync_info
          end

          results.flatten!

          # Return results
          {
            results: results,
            params: {
              synchronize: synchronize_clients
            }
          }
        end
      end
    end
  end
end
