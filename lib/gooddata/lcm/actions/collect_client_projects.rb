# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'
require 'concurrent'

module GoodData
  module LCM2
    class CollectClientProjects < BaseAction
      DESCRIPTION = 'Collect All Client Projects In Domain'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: true

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true
      end

      RESULT_HEADER = [
        :client_id,
        :project
      ]

      class << self
        def call(params)
          client = params.gdc_gd_client

          domain = client.domain(params.organization) || fail("Invalid domain name specified - #{params.organization}")
          all_segments = domain.segments

          segment_names = params.segments.map do |segment|
            segment.segment_id.downcase
          end

          segments = all_segments.select do |segment|
            segment_names.include?(segment.segment_id.downcase)
          end

          client_projects = Concurrent::Hash.new

          results = segments.pmap do |segment|
            segment.clients.map do |segment_client|
              project = segment_client.project

              res = {
                client_id: segment_client.client_id,
                project: project && project.pid
              }

              client_projects[segment_client.client_id] = {
                segment_client: segment_client,
                project: project
              }

              res
            end
          end

          {
            results: results.flatten,
            params: {
              client_projects: client_projects
            }
          }
        end
      end
    end
  end
end
