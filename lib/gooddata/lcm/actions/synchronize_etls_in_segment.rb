# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeETLsInSegment < BaseAction
      DESCRIPTION = 'Synchronize ETLs (CC/Ruby) In Segment'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Schedule Additional Parameters'
        param :additional_params, instance_of(Type::HashType), required: false

        description 'Schedule Additional Secure Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false
      end

      # will be updated later based on the way etl synchronization
      RESULT_HEADER = [
        :segment,
        :master_project,
        :client_id,
        :client_project,
        :status
      ]

      class << self
        def call(params)
          client = params.gdc_gd_client
          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")
          synchronize_segments = params.synchronize.group_by do |info|
            info[:segment_id]
          end

          results = synchronize_segments.pmap do |segment_id, synchronize|
            segment = domain.segments(segment_id)
            res = segment.synchronize_processes(
              synchronize.flat_map do |info|
                info[:to].flat_map do |to|
                  to[:pid]
                end
              end
            )

            res = GoodData::Helpers.symbolize_keys(res)

            if res[:syncedResult][:clients]
              res[:syncedResult][:clients].flat_map do |item|
                item = item[:client]
                {
                  segment: segment_id,
                  master_project: segment.master_project_id,
                  client_id: item[:id],
                  client_project: item[:project].split('/').last,
                  status: 'ok'
                }
              end
            else
              []
            end
          end

          params.synchronize.peach do |info|
            to_projects = info.to
            to_projects.peach do |entry|
              pid = entry[:pid]
              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")
              to_project.schedules.each do |schedule|
                additional_params = (params.additional_params || {})
                additional_params.merge!(
                  CLIENT_ID: entry[:client_id], # needed for ADD and CloudConnect ETL
                  GOODOT_CUSTOM_PROJECT_ID: entry[:client_id] # TMA-210
                )
                schedule.update_params(additional_params)
                schedule.update_hidden_params(params.additional_hidden_params || {})
                schedule.save
              end
            end
          end

          results.flatten
        end
      end
    end
  end
end
