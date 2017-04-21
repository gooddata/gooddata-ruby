# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class ImportObjectCollections < BaseAction
      DESCRIPTION = 'Import all objects in CollectXXX action to master projects'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true
      end

      class << self
        def call(params)
          BaseAction.check_params(PARAMS, params)

          results = []

          client = params.gdc_gd_client
          development_client = params.development_client

          params.synchronize.each do |info|
            from = info.from
            to_projects = info.to
            transfer_uris = info.transfer_uris

            from_project = development_client.projects(from) || fail("Invalid 'from' project specified - '#{from}'")

            to_projects.each do |entry|
              pid = entry[:pid]
              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

              from_project.partial_md_export(transfer_uris, project: to_project)

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
