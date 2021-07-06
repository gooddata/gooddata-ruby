# encoding: UTF-8
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeDataSetMapping < BaseAction
      DESCRIPTION = 'Synchronize Dataset Mappings'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Client used to connecting to development domain'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true
      end

      RESULT_HEADER = [
        :from,
        :to,
        :count,
        :status
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

            to_projects.peach do |to|
              pid = to[:pid]
              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

              params.gdc_logger.info "Transferring custom mapping, from project: '#{from.title}', PID: '#{from.pid}', to project: '#{to_project.title}', PID: '#{to_project.pid}'"
              res = GoodData::Project.transfer_dataset_mapping(
                  from,
                  to_project)
              results << res
            end
          end

          # Return results
          results.flatten
        end
      end
    end
  end
end
