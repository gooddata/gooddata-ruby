# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeSchedules < BaseAction
      DESCRIPTION = 'Synchronize ETL (CC/Ruby) Processes Schedules'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true
      end

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
            to_projects.each do |pid|
              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

              params.gdc_logger.info "Transferring Schedules, from project: '#{from.title}', PID: '#{from.pid}', to project: '#{to_project.title}', PID: '#{to_project.pid}'"
              GoodData::Project.transfer_schedules(from, to_project)

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
