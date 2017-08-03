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

        description 'Segments to provision'
        param :segments_filter, array_of(instance_of(Type::StringType)), required: false
      end

      class << self
        def call(params)
          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")
          domain_segments = domain.segments
          params.gdc_logger.info("Domain segments: #{domain_segments}")

          if params.segments_filter
            params.gdc_logger.info("Segments filter: #{params.segments_filter}")
            domain_segments.select! do |segment|
              params.segments_filter.include?(segment.segment_id)
            end
          end

          segments = domain_segments.pmap do |segment|
            project = nil

            begin
              project = segment.master_project
            rescue RestClient::BadRequest => e
              params.gdc_logger.error "Failed to retrieve master project for segment #{segment.id}. Error: #{e}"
              raise
            end

            raise "Master project for segment #{segment.id} doesn't exist." unless project

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
