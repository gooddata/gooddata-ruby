# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'
require_relative '../helpers/helpers'

module GoodData
  module LCM2
    class CollectTaggedObjects < BaseAction
      DESCRIPTION = 'Collect all objects tagged with the +$PRODUCTION_TAG+ from development projects'

      PARAMS = define_params(self) do
        description 'Development Client Used for Connecting to GD'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Production Tag Names'
        param :production_tags, array_of(instance_of(Type::StringType)), required: false

        description 'Production Tag Names'
        param :production_tag, instance_of(Type::StringType), required: false, deprecated: true, replacement: :production_tags

        description 'Segments to search for segment-specific production tags'
        param :segments, array_of(instance_of(Type::SegmentType)), required: false

        description 'Flag to mark if we need to transfer all objects'
        param :transfer_all, instance_of(Type::BooleanType), required: false, default: false
      end

      class << self
        def call(params)
          results = []
          segments_to_tags = Helpers.segment_production_tags(params.segments)
          transfer_all = GoodData::Helpers.to_boolean(params.transfer_all)
          return results unless params.production_tags || params.production_tag || segments_to_tags.any? || transfer_all
          development_client = params.development_client

          synchronize = params.synchronize.pmap do |info|
            from = info.from
            from_project = development_client.projects(from) || fail("Invalid 'from' project specified - '#{from}'")

            segment_tags = segments_to_tags[info.segment]
            production_tags = Helpers.parse_production_tags(params.production_tags || params.production_tag, segment_tags)
            objects = []
            if transfer_all
              vizs = MdObject.query('visualizationObject', MdObject, client: development_client, project: from_project)
              viz_widgets = MdObject.query('visualizationWidget', MdObject, client: development_client, project: from_project)
              objects = (from_project.reports.to_a + from_project.metrics.to_a + from_project.variables.to_a + vizs.to_a + viz_widgets.to_a).map(&:uri)
            elsif production_tags.any?
              objects = from_project.find_by_tag(production_tags)
            end

            info[:transfer_uris] ||= []
            info[:transfer_uris] += objects

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
