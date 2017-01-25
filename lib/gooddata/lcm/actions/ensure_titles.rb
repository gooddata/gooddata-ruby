# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class EnsureTitles < BaseAction
      DESCRIPTION = 'Ensure Project Titles - Based On Input Source Data'

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

          domain_segments = {}
          domain.segments.each do |segment|
            domain_segments[segment.segment_id] = {}
            segment.clients.each do |segment_client|
              domain_segments[segment.segment_id][segment_client.client_id] = segment_client.project
            end
          end

          params.clients.map do |segment_client|
            segment_id = segment_client.segment
            client_id  = segment_client.id
            project = domain_segments[segment_id][client_id]
            project.title = segment_client[:project_title]
            project.save

            {
              segment: segment_id,
              client: client_id,
              title: project.title
            }
          end
        end
      end
    end
  end
end
