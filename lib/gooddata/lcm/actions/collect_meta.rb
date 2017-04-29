# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class CollectMeta < BaseAction
      DESCRIPTION = "Collect tagged dashboards (or all dashboards if not specify production tag) \
      with objects inside dashboards (reports, metrics ...) from development projects"

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Tag Name'
        param :production_tag, instance_of(Type::StringType), required: false
      end

      class << self
        def call(params)
          results = []

          development_client = params.development_client

          synchronize = params.synchronize.map do |info|
            from = info.from
            from_project = development_client.projects(from) || fail("Invalid 'from' project specified - '#{from}'")

            if params.production_tag
              objects = GoodData::Dashboard.find_by_tag(params.production_tag, project: from_project, client: development_client)
            else
              objects = GoodData::Dashboard.all(project: from_project, client: development_client)
            end

            info[:transfer_uris] ||= []
            info[:transfer_uris] += objects.map(&:uri)

            results += objects.map do |uri|
              {
                project: from,
                transfer_uri: uri
              }
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
