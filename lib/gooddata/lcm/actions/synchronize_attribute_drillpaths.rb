# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeAttributeDrillpath < BaseAction
      DESCRIPTION = 'Synchronize Attribute Drillpath'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Development Client Used for Connecting to GD'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Additional Hidden Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false
      end

      RESULT_HEADER = [
        :from,
        :to,
        :status
      ]

      class << self
        def call(params)
          results = []

          client = params.gdc_gd_client
          development_client = params.development_client

          params.synchronize.peach do |info|
            from = info.from
            to = info.to

            from_project = development_client.projects(from) || fail("Invalid 'from' project specified - '#{from}'")
            to_projects = to.pmap do |entry|
              pid = entry[:pid]
              client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")
            end

            GoodData::LCM.transfer_attribute_drillpaths(from_project, to_projects)

            to_projects.each do |project|
              results << {
                from: from,
                to: project.pid,
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
