# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeProcesses < BaseAction
      DESCRIPTION = 'Synchronize ETL (CC/Ruby) Processes'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Uri of the source output stage. It must be in the same domain as the target project.'
        param :ads_output_stage_uri, instance_of(Type::StringType), required: false

        description 'Development Client Used for Connecting to GD'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true
      end

      RESULT_HEADER = [
        :from,
        :to,
        :status
      ]

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          results = []

          client = params.gdc_gd_client
          development_client = params.development_client

          params.synchronize.each do |info|
            from_project = info.from
            to_projects = info.to

            from = development_client.projects(from_project) || fail("Invalid 'from' project specified - '#{from_project}'")

            to_projects.each do |to|
              pid = to[:pid]
              client_id = to[:client_id]

              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

              params.gdc_logger.info "Transferring processes, from project: '#{from.title}', PID: '#{from.pid}', to project: '#{to_project.title}', PID: '#{to_project.pid}'"
              GoodData::Project.transfer_processes(from, to_project, ads_output_stage_uri: params.ads_output_stage_uri)

              to_project.add.output_stage.client_id = client_id if client_id && to_project.add.output_stage

              results << {
                from: from.pid,
                to: to_project.pid,
                status: 'ok'
              }
            end
          end

          # Return results
          results
        end
      end
    end
  end
end
