# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeMeta < BaseAction
      DESCRIPTION = 'Synchronize Metadata'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true
      end

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          results = []

          client = params.gdc_gd_client
          development_client = params.development_client

          params.synchronize.each do |info|
            from = info.from
            to = info.to

            from_project = development_client.projects(from) || fail("Invalid 'from' project specified - '#{from}'")
            to_projects = to.map do |entry|
              client.projects(entry[:pid])
            end

            GoodData::LCM.transfer_meta(from_project, to_projects)

            to_projects.each do |project|
              results << {
                from: from,
                to: project.pid,
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
