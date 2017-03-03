# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeTaggedObjects < BaseAction
      DESCRIPTION = 'Purge LCM Clients'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Client Used for Connecting to GD'
        param :development_client, instance_of(Type::GdClientType), required: true
      end

      RESULT_HEADER = [
        :object
      ]

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          client = params.gdc_gd_client
          development_client = params.development_client

          tag = params.production_tag

          res = []
          params.synchronize.each do |info|
            from_project_pid = info.from
            to_projects = info.to

            from_project = development_client.projects(from_project_pid)
            res = to_projects.map do |to_project_pid|
              to_project = client.projects(to_project_pid)
              GoodData::Project.transfer_tagged_stuff(from_project, to_project, tag) if tag
            end
          end

          res.flatten.uniq.map do |obj|
            {
              object: obj
            }
          end
        end
      end
    end
  end
end
