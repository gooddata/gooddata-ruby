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
      end

      class << self
        def call(params)
          results = []
          disable_pp_dashboard_permission = GoodData::Helpers.to_boolean(params.disable_pp_dashboard_permission)

          if disable_pp_dashboard_permission
            params.gdc_logger.info "Skip synchronize Pixel Perfect dashboard permission."
          else
            client = params.gdc_gd_client
            development_client = params.development_client

            params.synchronize.peach do |info|
              from_project = info.from
              to_projects = info.to

              from = development_client.projects(from_project) || fail("Invalid 'from' project specified - '#{from_project}'")
              source_dashboards = from.dashboards

              params.gdc_logger.info "Transferring Pixel Perfect Dashboard permission, from project: '#{from.title}', PID: '#{from.pid}' for dashboard(s): #{source_dashboards.map { |d| "#{d.title.inspect}" }.join(', ')}" # rubocop:disable Metrics/LineLength
              to_projects.peach do |entry|
                pid = entry[:pid]
                to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

                target_dashboards = to_project.dashboards
                GoodData::Project.transfer_dashboard_permission(from, to_project, source_dashboards, target_dashboards)
              end

              results << {
                from_project_name: from.title,
                from_project_pid: from.pid,
                status: 'ok'
              }
            end
          end

          results
        end
      end
    end
  end
end
