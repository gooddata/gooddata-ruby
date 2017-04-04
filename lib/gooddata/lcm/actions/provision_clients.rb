# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class ProvisionClients < BaseAction
      DESCRIPTION = 'Provisions LCM Clients'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: true

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true
      end

      RESULT_HEADER = [
        :id,
        :status,
        :project_uri,
        :error,
        :type
      ]

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          synchronize_projects = []
          results = params.segments.map do |segment|
            tmp = domain.provision_client_projects(segment.segment_id).map do |m|
              Hash[m.each_pair.to_a].merge(type: :provision_result)
            end

            unless tmp.empty?
              synchronize_projects << {
                segment_id: segment.segment_id,
                from: segment.development_pid,
                to: tmp.map do |entry|
                  {
                    pid: entry[:project_uri].split('/').last,
                    client_id: entry[:id]
                  }
                end
              }
            end

            tmp
          end

          results.flatten!

          # Return results
          {
            results: results,
            params: {
              synchronize: synchronize_projects
            }
          }
        end
      end
    end
  end
end
