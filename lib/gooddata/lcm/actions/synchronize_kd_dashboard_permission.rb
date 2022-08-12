# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'
require 'thread_safe'

module GoodData
  module LCM2
    class SynchronizeKDDashboardPermissions < BaseAction
      DESCRIPTION = 'Synchronize KD Dashboard Permission'

      PARAMS = define_params(self) do
        description 'Client used to connecting to development domain'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true

        description 'Additional Hidden Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Disable synchronizing dashboard permissions for AD/KD dashboards.'
        param :disable_kd_dashboard_permission, instance_of(Type::BooleanType), required: false, default: false
      end

      class << self
        def call(params)
          results = ThreadSafe::Array.new

          disable_kd_dashboard_permission = GoodData::Helpers.to_boolean(params.disable_kd_dashboard_permission)

          # rubocop:disable Style/UnlessElse
          unless disable_kd_dashboard_permission
            dashboard_type = "KD"
            dev_client = params.development_client
            gdc_client = params.gdc_gd_client

            params.synchronize.peach do |param_info|
              from_project_info = param_info.from
              to_projects_info = param_info.to

              from_project = dev_client.projects(from_project_info) || fail("Invalid 'from' project specified - '#{from_project_info}'")
              from_dashboards = from_project.analytical_dashboards

              params.gdc_logger.info "Transferring #{dashboard_type} Dashboard permission, from project: '#{from_project.title}', PID: '#{from_project.pid}' for dashboard(s): #{from_dashboards.map { |d| "#{d.title.inspect}" }.join(', ')}" # rubocop:disable Metrics/LineLength
              to_projects_info.peach do |item|
                to_project_pid = item[:pid]
                to_project = gdc_client.projects(to_project_pid) || fail("Invalid 'to' project specified - '#{to_project_pid}'")

                to_dashboards = to_project.analytical_dashboards
                GoodData::Project.transfer_dashboard_permission(from_project, to_project, from_dashboards, to_dashboards)
              end

              results << {
                from_project_name: from_project.title,
                from_project_pid: from_project.pid,
                status: 'ok'
              }
            end
          else
            params.gdc_logger.info "Skip synchronize KD dashboard permission."
          end

          results
          # rubocop:enable Style/UnlessElse
        end
      end
    end
  end
end
