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
          # domain_segments = domain.segments

          # segments = params.segments.map do |seg|
          #   domain_segments.find do |s|
          #     s.segment_id == seg.segment_id
          #   end
          # end

          results = []

          client_id_column = params.client_id_column || 'client_id'
          segment_id_column = params.segment_id_column || 'segment_id'

          data_source = GoodData::Helpers::DataSource.new(params.input_source)
          input_data = File.open(data_source.realize(params), 'r:UTF-8')
          sync_info = {}
          CSV.foreach(input_data, :headers => true, :return_headers => false, encoding: 'utf-8') do |row|
            client_id = row[client_id_column]
            segment_id = row[segment_id_column]
            if sync_info[segment_id]
              sync_info[segment_id] += [client_id]
            else
              sync_info[segment_id] = [client_id]
            end
          end

          synchronize_clients = []
          p sync_info
          sync_info.each do |segment_id, clients|
            segment = params.segments.find do |s|
              s.segment_id == segment_id
            end
            if segment
              segment = domain.segments(segment.segment_id)
              synchronize_clients << {
                from: segment.master_project.pid,
                segment_id: segment_id,
                to: clients.map do |input_client_id|
                  p segment.clients
                  client_id = segment.clients.find do |c|
                    c.client_id == input_client_id
                  end
                  if client_id
                    results << {
                      from_name: segment.master_project.title,
                      from_pid: segment.master_project.pid,
                      to_name: client_id.project.title,
                      to_pid: client_id.project.pid
                    }

                    {
                      pid: client_id.project.pid,
                      client_id: input_client_id
                    }
                  else
                    params.gdc_logger.info "Segment #{segment_id} does not contain client #{input_client_id}!"
                    nil
                  end
                end.compact
              }
            else
              params.gdc_logger.info "Segment #{segment_id} cannot be found!"
            end
          end

          # synchronize_clients = segments.map do |segment|
          #   replacements = {
          #     table_name: params.release_table_name || DEFAULT_TABLE_NAME,
          #     segment_id: segment.segment_id
          #   }

          #   path = File.expand_path('../../data/select_from_lcm_release.sql.erb', __FILE__)
          #   query = GoodData::Helpers::ErbHelper.template_file(path, replacements)

          #   res = params.ads_client.execute_select(query)

          #   p res
          #   # TODO: Check res.first.nil? || res.first[:master_project_id].nil?
          #   master = client.projects(res.first[:master_project_id])
          #   master_pid = master.pid
          #   master_name = master.title

          #   sync_info = {
          #     from: master_pid,
          #     segment_id: segment.segment_id,
          #     to: segment.clients.map do |segment_client|
          #       client_project = segment_client.project
          #       to_pid = client_project.pid
          #       results << {
          #         from_name: master_name,
          #         from_pid: master_pid,
          #         to_name: client_project.title,
          #         to_pid: to_pid
          #       }

          #       {
          #         pid: to_pid,
          #         client_id: segment_client.client_id
          #       }
          #     end
          #   }

          #   sync_info
          # end

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
