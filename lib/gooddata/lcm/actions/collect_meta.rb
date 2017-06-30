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
        description 'Production Tag Name'
        param :production_tag, instance_of(Type::StringType), required: false

        description 'Development Client Used for Connecting to GD'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Segments to search for segment-specific production tags'
        param :segments, array_of(instance_of(Type::SegmentType)), required: false

        description 'Flag to mark if we need to transfer all objects'
        param :transfer_all, instance_of(Type::BooleanType), required: false, default: false
      end

      class << self
        def call(params)
          results = []

          development_client = params.development_client
          segments_to_tags = Helpers.segment_production_tags(params.segments)
          transfer_all = GoodData::Helpers.to_boolean(params.transfer_all)

          synchronize = params.synchronize.pmap do |info|
            from = info.from
            from_project = development_client.projects(from) || fail("Invalid 'from' project specified - '#{from}'")

            segment_tags = segments_to_tags[info.segment]
            production_tags = Helpers.parse_production_tags(params.production_tag, segment_tags)

            if transfer_all || production_tags.empty?
              objects = GoodData::Dashboard.all(
                project: from_project,
                client: development_client
              )
            else
              objects = GoodData::Dashboard.find_by_tag(
                production_tags,
                project: from_project,
                client: development_client
              )
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
