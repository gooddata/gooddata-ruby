# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

require 'thread_safe'
require 'json'

module GoodData
  module LCM2
    class SynchronizePPDashboardPermissions < BaseAction
      DESCRIPTION = 'Synchronize Pixel Perfect Dashboard Permission'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Client used to connecting to development domain'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true

        description 'Additional Hidden Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false

        description 'Disable synchronizing dashboard permissions for Pixel Perfect dashboards'
        param :disable_pp_dashboard_permission, instance_of(Type::BooleanType), required: false, default: false

        description 'Abort on error'
        param :abort_on_error, instance_of(Type::StringType), required: false

        description 'Collect synced status'
        param :collect_synced_status, instance_of(Type::BooleanType), required: false

        description 'Sync failed list'
        param :sync_failed_list, instance_of(Type::HashType), required: false

        description 'Number Of Threads'
        param :number_of_threads_synchronize_pp_dashboard_permissions, instance_of(Type::StringType), required: false, default: '10'
      end

      class << self
        def call(params)
          results = []
          disable_pp_dashboard_permission = GoodData::Helpers.to_boolean(params.disable_pp_dashboard_permission)
          collect_synced_status = collect_synced_status(params)
          number_of_threads = Integer(params.number_of_threads_synchronize_pp_dashboard_permissions || '10')
          GoodData.logger.info "Number of threads using synchronize pixel perfect dashboard permissions #{number_of_threads}" if number_of_threads != 10
          failed_projects = ThreadSafe::Array.new

          if disable_pp_dashboard_permission
            params.gdc_logger.info "Skip synchronize Pixel Perfect dashboard permission."
          else
            client = params.gdc_gd_client
            development_client = params.development_client
            failed_projects = ThreadSafe::Array.new

            params.synchronize.peach do |info|
              from_project = info.from
              to_projects = info.to
              sync_success = false

              from = development_client.projects(from_project)
              unless from
                process_failed_project(from_project, "Invalid 'from' project specified - '#{from_project}'", failed_projects, collect_synced_status)
                next
              end

              source_dashboards = from.dashboards

              params.gdc_logger.info "Transferring Pixel Perfect Dashboard permission, from project: '#{from.title}', PID: '#{from.pid}' for dashboard(s): #{source_dashboards.map { |d| "#{d.title.inspect}" }.join(', ')}" # rubocop:disable Metrics/LineLength
              to_projects.peach(number_of_threads) do |entry|
                pid = entry[:pid]
                next if sync_failed_project(pid, params)

                to_project = client.projects(pid)
                unless to_project
                  process_failed_project(pid, "Invalid 'to' project specified - '#{pid}'", failed_projects, collect_synced_status)
                  next
                end

                target_dashboards = to_project.dashboards
                begin
                  GoodData::Project.transfer_dashboard_permission(from, to_project, source_dashboards, target_dashboards)
                  sync_success = true
                rescue StandardError => err
                  process_failed_project(pid, err.message, failed_projects, collect_synced_status)
                end
              end

              results << {
                from_project_name: from.title,
                from_project_pid: from.pid,
                status: 'ok'
              } if sync_success
            end
          end

          process_failed_projects(failed_projects, short_name, params) if collect_synced_status
          results
        end
      end
    end
  end
end
