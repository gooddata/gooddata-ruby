# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeComputedAttributes < BaseAction
      DESCRIPTION = 'Synchronize Computed Attributes'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true
      end

      class << self
        def call(params)
          BaseAction.check_params(PARAMS, params)
          results = []
          development_client = params.development_client
          client = params.gdc_gd_client

          params.synchronize.peach do |info|
            from = info.from
            to_projects = info.to

            from_project = development_client.projects(from) || fail("Invalid 'from' project specified - '#{from}'")
            params.gdc_logger.info "Synchronize Computed Attributes, project: '#{from_project.title}', PID: #{from_project.pid}"

            blueprint = from_project.blueprint
            to_projects.peach do |entry|
              pid = entry[:pid]
              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

              params.gdc_logger.info "Synchronizing Computed Attributes from project: '#{to_project.title}', PID: #{pid}"
              to_project.update_from_blueprint(blueprint)

              results << {
                from: from,
                to: pid,
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
