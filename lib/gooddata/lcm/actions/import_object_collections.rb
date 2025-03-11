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

        description 'Client used to connecting to development domain'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Number Of Threads'
        param :number_of_threads, instance_of(Type::StringType), required: false, default: '10'
      end

      class << self
        def call(params)
          results = []

          client = params.gdc_gd_client
          development_client = params.development_client
          number_of_threads = Integer(params.number_of_threads || '10')

          params.synchronize.peach(number_of_threads) do |info|
            from = info.from
            to_projects = info.to
            transfer_uris = info.transfer_uris

            from_project = development_client.projects(from) || fail("Invalid 'from' project specified - '#{from}'")

            to_projects.peach(number_of_threads) do |entry|
              pid = entry[:pid]
              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

              if transfer_uris.any?
                from_project.partial_md_export(transfer_uris, project: to_project)
              end

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
