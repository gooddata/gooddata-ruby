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

            if res[:syncedResult][:errors]
              params.gdc_logger.error "Error: #{res[:syncedResult][:errors].pretty_inspect}"
              fail "Failed to sync processes/schedules for segment #{segment_id}"
            end

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

          delete_extra_process_schedule = GoodData::Helpers.to_boolean(params.delete_extra_process_schedule)

          params.synchronize.peach do |info|
            if delete_extra_process_schedule
              from_project = client.projects(info.from) || fail("Invalid 'from' project specified - '#{info.from}'")
              from_project_processes = from_project.processes
              from_project_process_id_names = Hash[from_project_processes.map { |process| [process.process_id, process.name] }]
              from_project_process_names = from_project_processes.map(&:name)
              from_project_schedule_names = from_project.schedules.map { |schedule| [schedule.name, from_project_process_id_names[schedule.process_id]] }
            end

            to_projects = info.to
            to_projects.peach do |entry|
              pid = entry[:pid]
              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

              if delete_extra_process_schedule
                to_project_process_id_names = {}
                to_project.processes.each do |process|
                  if from_project_process_names.include?(process.name)
                    to_project_process_id_names[process.process_id] = process.name
                  else
                    process.delete
                  end
                end
              end

              to_project.schedules.each do |schedule|
                if delete_extra_process_schedule
                  unless from_project_schedule_names.include?([schedule.name, to_project_process_id_names[schedule.process_id]])
                    schedule.delete
                    next
                  end
                end

                additional_params = params.additional_params || {}
                additional_params.merge!(
                  CLIENT_ID: entry[:client_id], # needed for ADD and CloudConnect ETL
                  GOODOT_CUSTOM_PROJECT_ID: entry[:client_id] # TMA-210
                )
                schedule.update_params(additional_params)
                schedule.update_hidden_params(params.additional_hidden_params || {})
                schedule.enable
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
