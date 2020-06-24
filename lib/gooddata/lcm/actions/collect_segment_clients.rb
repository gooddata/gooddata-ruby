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

        description 'ADS Client'
        param :ads_client, instance_of(Type::AdsClientType), required: false

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'Table Name'
        param :release_table_name, instance_of(Type::StringType), required: false

        description 'DataProduct'
        param :data_product, instance_of(Type::GDDataProductType), required: false

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false
      end

      RESULT_HEADER = [
        :from_name,
        :from_pid,
        :to_name,
        :to_pid
      ]

      class << self
        def call(params)
          client = params.gdc_gd_client

          results = []
          synchronize_clients = params[:segments].map do |segment_hash|
            segment = segment_hash[:segment]
            segment_clients = segment.clients
            missing_project_clients = segment_clients.reject(&:project?).map(&:client_id)

            raise "Client(s) missing workspace: #{missing_project_clients.join(', ')}. Please make sure all clients have workspace." unless missing_project_clients.empty?

            domain_name = params.organization || params.domain
            fail "Either organisation or domain has to be specified in params" unless domain_name

            client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

            if params.ads_client
              latest_master = GoodData::LCM2::Helpers.latest_master_project_from_ads(
                params.release_table_name,
                params.ads_client,
                segment.segment_id
              )
            else
              data_product = params.data_product
              data_product_id = data_product.data_product_id
              latest_master = GoodData::LCM2::Helpers.latest_master_project_from_nfs(domain_name, data_product_id, segment.segment_id)
            end
            raise 'Release table has no data' unless latest_master

            latest_master = client.projects(latest_master[:master_project_id])

            # TODO: Check res.first.nil? || res.first[:master_project_id].nil?
            master_pid = latest_master.pid
            master_name = latest_master.title

            previous_master = segment_hash[:segment_master] if
              segment_hash[:segment_master] &&
              segment_hash[:segment_master].pid != latest_master.pid

            sync_info = {
              segment_id: segment.segment_id,
              from: master_pid,
              previous_master: previous_master,
              latest_master: latest_master,
              to: segment_clients.map do |segment_client|
                client_project = segment_client.project
                to_pid = client_project.pid
                results << {
                  from_name: master_name,
                  from_pid: master_pid,
                  to_name: client_project.title,
                  to_pid: to_pid,
                  previous_master: previous_master
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
