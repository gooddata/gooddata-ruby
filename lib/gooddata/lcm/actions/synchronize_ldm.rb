# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeLdm < BaseAction
      DESCRIPTION = 'Synchronize Logical Data Model'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Development Client Used for Connecting to GD'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'LDM Update Preference'
        param :update_preference, instance_of(Type::UpdatePreferenceType), required: false

        description 'Specifies whether to transfer computed attributes'
        param :include_computed_attributes, instance_of(Type::BooleanType), required: false, default: true
      end

      class << self
        def call(params)
          # set default value for include_computed_attributes
          # (we won't have to do this after TMA-690)
          include_ca = params.include_computed_attributes
          include_ca = true if include_ca.nil?
          include_ca = include_ca.to_b

          results = []

          client = params.gdc_gd_client
          development_client = params.development_client

          synchronize = params.synchronize.map do |info|
            from_project = info.from
            to_projects = info.to

            from = development_client.projects(from_project) || fail("Invalid 'from' project specified - '#{from_project}'")
            params.gdc_logger.info "Creating Blueprint, project: '#{from.title}', PID: #{from.pid}"

            blueprint = from.blueprint(include_ca: include_ca)
            info[:to] = to_projects.pmap do |entry|
              pid = entry[:pid]
              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

              params.gdc_logger.info "Updating from Blueprint, project: '#{to_project.title}', PID: #{pid}"
              ca_scripts = to_project.update_from_blueprint(blueprint, update_preference: params.update_preference, execute_ca_scripts: false)

              entry[:ca_scripts] = ca_scripts

              results << {
                from: from_project,
                to: pid,
                status: 'ok'
              }
              entry
            end

            info
          end

          {
            results: results,
            params: {
              synchronize: synchronize
            }
          }
        end
      end
    end
  end
end
