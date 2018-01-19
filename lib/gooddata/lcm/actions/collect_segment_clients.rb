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
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'ADS Client'
        param :ads_client, instance_of(Type::AdsClientType), required: true

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'Table Name'
        param :release_table_name, instance_of(Type::StringType), required: false

        description 'DataProduct'
        param :data_product, instance_of(Type::GDDataProductType), required: false
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

          results = []
          synchronize_clients = segments.map do |segment|
            segment_clients = segment.clients
            missing_project_clients = segment_clients.reject(&:project?).map(&:client_id)

            raise "Client(s) missing workspace: #{missing_project_clients.join(', ')}. Please make sure all clients have workspace." unless missing_project_clients.empty?

            replacements = {
              table_name: params.release_table_name || DEFAULT_TABLE_NAME,
              segment_id: segment.segment_id
            }

            path = File.expand_path('../../data/select_from_lcm_release.sql.erb', __FILE__)
            query = GoodData::Helpers::ErbHelper.template_file(path, replacements)

            res = params.ads_client.execute_select(query)

            sorted = res.sort_by { |row| row[:version] }
              .map { |row| row[:master_project_id] }
            current_master = client.projects(sorted[-1])
            previous_master = nil
            previous_master = client.projects(sorted[-2]) if sorted.length > 1

            # TODO: Check res.first.nil? || res.first[:master_project_id].nil?
            master_pid = current_master.pid
            master_name = current_master.title

            sync_info = {
              segment_id: segment.segment_id,
              from: master_pid,
              diff_ldm_against: previous_master,
              to: segment_clients.map do |segment_client|
                client_project = segment_client.project
                to_pid = client_project.pid
                results << {
                  from_name: master_name,
                  from_pid: master_pid,
                  to_name: client_project.title,
                  to_pid: to_pid,
                  diff_ldm_against: previous_master && previous_master.pid
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
