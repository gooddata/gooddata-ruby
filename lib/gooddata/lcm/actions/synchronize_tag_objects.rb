# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeTagObjects < BaseAction
      DESCRIPTION = "Synchronizes objects that have the production_tag even though they would normally be ignored \
      (e.g. metrics that are not used in any dashboards)."

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Client used to connecting to development domain'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Production Tag Names'
        param :production_tags, array_of(instance_of(Type::StringType)), required: false

        description 'Production Tag Names'
        param :production_tag, instance_of(Type::StringType), required: false, deprecated: true, replacement: :production_tags

        description 'Additional Hidden Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false
      end

      class << self
        def call(params)
          return [] unless params.production_tags || params.production_tag

          results = []

          client = params.gdc_gd_client
          development_client = params.development_client

          params.synchronize.each do |info|
            from_project = info.from
            to_projects = info.to

            from = development_client.projects(from_project) || fail("Invalid 'from' project specified - '#{from_project}'")

            to_projects.each do |entry|
              pid = entry[:pid]
              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

              GoodData::Project.transfer_tagged_stuff(from, to_project, params.production_tags || params.production_tag)

              results << {
                from: from_project,
                to: pid,
                tag: params.production_tags || params.production_tag,
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
