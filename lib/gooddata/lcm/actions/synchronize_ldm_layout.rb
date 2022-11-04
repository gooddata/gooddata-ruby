# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2022 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeLdmLayout < BaseAction
      DESCRIPTION = 'Synchronize LDM Layout'

      PARAMS = define_params(self) do
        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true

        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Client used to connecting to development domain'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Abort on error'
        param :abort_on_error, instance_of(Type::StringType), required: false

        description 'Collect synced status'
        param :collect_synced_status, instance_of(Type::BooleanType), required: false

        description 'Sync failed list'
        param :sync_failed_list, instance_of(Type::HashType), required: false
      end

      RESULT_HEADER = %i[from to status]

      class << self
        def call(params)
          results = []

          client = params.gdc_gd_client
          development_client = params.development_client
          gdc_logger = params.gdc_logger
          collect_synced_status = collect_synced_status(params)
          failed_projects = ThreadSafe::Array.new

          params.synchronize.peach do |info|
            from_project = info.from
            to_projects = info.to

            from = development_client.projects(from_project)
            unless from
              process_failed_project(from_project, "Invalid 'from' project specified - '#{from_project}'", failed_projects, collect_synced_status)
              next
            end

            from_pid = from.pid
            from_title = from.title
            from_ldm_layout = from.ldm_layout

            if from_ldm_layout&.dig('ldmLayout', 'layout').nil? || from_ldm_layout['ldmLayout']['layout'].empty?
              gdc_logger.info "Project: '#{from_title}', PID: '#{from_pid}' has no ldm layout, skip synchronizing ldm layout."
            else
              to_projects.peach do |to|
                pid = to[:pid]
                to_project = client.projects(pid)
                unless to_project
                  process_failed_project(pid, "Invalid 'from' project specified - '#{pid}'", failed_projects, collect_synced_status)
                  next
                end

                next if sync_failed_project(pid, params)

                gdc_logger.info "Transferring ldm layout, from project: '#{from_title}', PID: '#{from_pid}', to project: '#{to_project.title}', PID: '#{to_project.pid}'"
                res = to_project.save_ldm_layout(from_ldm_layout)

                if res[:status] == 'OK' || !collect_synced_status
                  res[:from] = from_pid
                  results << res
                else
                  warning_message = "Failed to transfer ldm layout from project: '#{from_pid}' to project: '#{to_project.title}'"
                  process_failed_project(pid, warning_message, failed_projects, collect_synced_status)
                end
              end
            end
          end

          process_failed_projects(failed_projects, short_name, params) if collect_synced_status
          # Return results
          results.flatten
        end
      end
    end
  end
end
