# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
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
      end

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          segment_names = params.segment_filter || domain.segments.map(&:segment_id)
          results = domain.provision_client_projects(nil).map do |m|
            Hash[m.each_pair.to_a].merge(type: :provision_result)
          end

          domain_segments = domain.segments
          synchronize_projects = domain_segments.map do |segment|
            {
              from: segment.master_project.pid,
              to: segment.clients.map do |segment_client|
                segment_client.project.pid
              end
            }
          end

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
