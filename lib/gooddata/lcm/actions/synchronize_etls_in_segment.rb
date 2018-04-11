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

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Schedule Additional Parameters'
        param :additional_params, instance_of(Type::HashType), required: false

        description 'Schedule Additional Secure Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false

        description 'Schedule Parameters'
        param :schedule_params, instance_of(Type::HashType), required: false, default: {}

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::GDDataProductType), required: false

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true

        description 'Delete extra process schedule flag'
        param :delete_extra_process_schedule, instance_of(Type::BooleanType), required: false, default: true
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
          data_product = params.data_product
          synchronize_segments = params.synchronize.group_by do |info|
            info[:segment_id]
          end

          results = synchronize_segments.pmap do |segment_id, synchronize|
            segment = data_product.segments.find { |s| s.segment_id == segment_id }
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
          schedule_params = params.schedule_params || {}
          params_for_all_projects = schedule_params[:all_clients] || {}
          params_for_all_schedules_in_all_projects = params_for_all_projects[:all_schedules]

          params.synchronize.peach do |info|
            from_project_etl_names = get_process_n_schedule_names(client, info.from) if delete_extra_process_schedule

            to_projects = info.to
            to_projects.peach do |entry|
              pid = entry[:pid]
              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

              if delete_extra_process_schedule
                to_project_process_id_names = {}
                to_project.processes.each do |process|
                  if from_project_etl_names[:processes].include?(process.name)
                    to_project_process_id_names[process.process_id] = process.name
                  else
                    process.delete
                  end
                end
              end

              client_id = entry[:client_id]
              params_for_this_client = schedule_params[client_id] || {}
              params_for_all_schedules_in_this_client = params_for_this_client[nil]

              to_project.set_metadata('GOODOT_CUSTOM_PROJECT_ID', client_id) # TMA-210

              to_project.schedules.each do |schedule|
                if delete_extra_process_schedule
                  unless from_project_etl_names[:schedules].include?([schedule.name, to_project_process_id_names[schedule.process_id]])
                    schedule.delete
                    next
                  end
                end

                schedule.update_params(params.additional_params) if params.additional_params
                schedule.update_params(
                  CLIENT_ID: client_id, # needed for ADD and CloudConnect ETL
                  GOODOT_CUSTOM_PROJECT_ID: client_id # TMA-210
                )

                schedule.update_params(params_for_all_schedules_in_all_projects) if params_for_all_schedules_in_all_projects
                schedule.update_params(params_for_all_projects[schedule.name]) if params_for_all_projects[schedule.name]
                schedule.update_params(params_for_all_schedules_in_this_client) if params_for_all_schedules_in_this_client
                schedule.update_params(params_for_this_client[schedule.name]) if params_for_this_client[schedule.name]

                schedule.update_hidden_params(params.additional_hidden_params) if params.additional_hidden_params
                schedule.enable
                schedule.save
              end
            end
          end

          results.flatten
        end

        private

        def get_process_n_schedule_names(client, project_id)
          project = client.projects(project_id) || fail("Invalid 'from' project specified - '#{project_id}'")
          processes = project.processes
          process_id_names = Hash[processes.map { |process| [process.process_id, process.name] }]

          {
            processes: processes.map(&:name),
            schedules: project.schedules.map { |schedule| [schedule.name, process_id_names[schedule.process_id]] }
          }
        end
      end
    end
  end
end
