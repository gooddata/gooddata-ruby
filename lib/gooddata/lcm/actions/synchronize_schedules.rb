# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'
require_relative '../helpers/helpers'

module GoodData
  module LCM2
    class SynchronizeSchedules < BaseAction
      DESCRIPTION = 'Synchronize ETL (CC/Ruby) Processes Schedules'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Development Client Used for Connecting to GD'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Schedule Additional Parameters'
        param :additional_params, instance_of(Type::HashType), required: false

        description 'Schedule Additional Secure Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false
      end

      RESULT_HEADER = [
        :from,
        :to,
        :process_name,
        :schedule_name,
        :type,
        :state
      ]

      class << self
        def call(params)
          results = []

          client = params.gdc_gd_client
          development_client = params.development_client

          params.synchronize.peach do |info|
            from_project = info.from
            to_projects = info.to

            from = development_client.projects(from_project) || fail("Invalid 'from' project specified - '#{from_project}'")
            to_projects.peach do |entry|
              pid = entry[:pid]
              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

              params.gdc_logger.info "Transferring Schedules, from project: '#{from.title}', PID: '#{from.pid}', to project: '#{to_project.title}', PID: '#{to_project.pid}'"
              res = GoodData::Project.transfer_schedules(from, to_project).sort_by do |item|
                item[:status]
              end

              results += res.map do |item|
                schedule = item[:schedule]

                additional_hidden_params = params.additional_hidden_params || {}

                Helpers.sanitize_hidden_params_for_transfer(
                  schedule,
                  additional_hidden_params,
                  params.gdc_logger
                )
                schedule.update_params(params.additional_params || {})
                schedule.update_hidden_params(additional_hidden_params)
                schedule.disable
                schedule.save

                {
                  from: from.pid,
                  to: to_project.pid,
                  process_name: item[:process].name,
                  schedule_name: schedule.name,
                  type: item[:process].type,
                  state: item[:state]
                }
              end
            end
          end

          results
        end
      end
    end
  end
end
