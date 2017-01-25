# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class PurgeClients < BaseAction
      DESCRIPTION = 'Purge LCM Clients'

      PARAMS = define_params(self) do
        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: true

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'Delete Extra Clients'
        param :delete_extra, instance_of(Type::BooleanType), required: false, default: false

        description 'Physically Delete Client Projects'
        param :delete_projects, instance_of(Type::BooleanType), required: false, default: false
      end

      RESULT_HEADER = [
        :client_id,
        :project,
        :status
      ]

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

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

          results = segments.map do |segment|
            segment.clients.map do |client|
              project = client.project
              res = {
                client_id: client.client_id,
                project: project.pid
              }

              if project.is_deleted?
                client.delete
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
