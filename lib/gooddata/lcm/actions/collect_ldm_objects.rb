# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class CollectLdmObjects < BaseAction
      DESCRIPTION = "Collect all objects in LDM: attributes (include CAs), facts, datasets"

      PARAMS = define_params(self) do
        description 'Development Client Used for Connecting to GD'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true
      end

      class << self
        def call(params)
          results = []

          development_client = params.development_client

          synchronize = params.synchronize.pmap do |info|
            from = info.from
            from_project = development_client.projects(from) || fail("Invalid 'from' project specified - '#{from}'")
            objects = (from_project.attributes.to_a + from_project.labels.to_a + from_project.datasets.to_a + from_project.facts.to_a).map(&:uri)

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
