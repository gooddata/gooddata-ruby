# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class CollectSegments < BaseAction
      DESCRIPTION = 'Collect Segments from API'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: true
      end

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")
          domain_segments = domain.segments

          segments = domain_segments.map do |segment|
            project = segment.master_project

            # TODO: Check if project exists!

            {
              segment_id: segment.segment_id,
              development_pid: project.pid,
              driver: project.driver.downcase,
              master_name: project.title
            }
          end

          segments.compact!

          # Return results
          {
            results: segments,
            params: {
              segments: segments
            }
          }
        end
      end
    end
  end
end
