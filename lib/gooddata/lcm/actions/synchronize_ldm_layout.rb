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
      end

      RESULT_HEADER = %i[from to status]

      class << self
        def call(params)
          results = []

          client = params.gdc_gd_client
          development_client = params.development_client
          gdc_logger = params.gdc_logger

          params.synchronize.peach do |info|
            from_project = info.from
            to_projects = info.to

            from = development_client.projects(from_project) || fail("Invalid 'from' project specified - '#{from_project}'")
            from_pid = from.pid
            from_title = from.title
            from_ldm_layout = from.ldm_layout

            if from_ldm_layout&.dig('ldmLayout', 'layout').nil? || from_ldm_layout['ldmLayout']['layout'].empty?
              gdc_logger.info "Project: '#{from_title}', PID: '#{from_pid}' has no ldm layout, skip synchronizing ldm layout."
            else
              to_projects.peach do |to|
                pid = to[:pid]
                to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

                gdc_logger.info "Transferring ldm layout, from project: '#{from_title}', PID: '#{from_pid}', to project: '#{to_project.title}', PID: '#{to_project.pid}'"
                res = to_project.save_ldm_layout(from_ldm_layout)
                res[:from] = from_pid
                results << res
              end
            end
          end
          # Return results
          results.flatten
        end
      end
    end
  end
end
