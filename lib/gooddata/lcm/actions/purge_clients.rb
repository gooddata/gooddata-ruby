# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class PurgeClients < BaseAction
      DESCRIPTION = 'Purge LCM Clients'

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
        :project,
        :status
      ]

      class << self
        def call(params)
          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")
          all_segments = domain.segments

          segment_names = params.segments.map do |segment|
            segment.segment_id.downcase
          end

          segments = all_segments.select do |segment|
            segment_names.include?(segment.segment_id.downcase)
          end

          results = segments.pmap do |segment|
            segment.clients.map do |segment_client|
              project = segment_client.project
              res = {
                client_id: segment_client.client_id,
                project: project && project.pid
              }

              if project.nil? || project.deleted?
                segment_client.delete
                res[:status] = 'purged'
              else
                res[:status] = 'ok - not purged'
              end

              res
            end
          end

          # Return results
          results.flatten
        end
      end
    end
  end
end
