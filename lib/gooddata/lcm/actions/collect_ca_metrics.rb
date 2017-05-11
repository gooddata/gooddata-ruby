# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class CollectComputedAttributeMetrics < BaseAction
      DESCRIPTION = 'Collect all metrics which is used in computed attributes in development projects'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true
      end

      class << self
        def call(params)
          BaseAction.check_params(PARAMS, params)
          results = []
          development_client = params.development_client

          synchronize = params.synchronize.pmap do |info|
            from = info.from
            from_project = development_client.projects(from) || fail("Invalid 'from' project specified - '#{from}'")

            metric_uris = from_project.computed_attributes.flat_map { |a| a.using('metric').map { |m| m['link'] } }

            info[:transfer_uris] ||= []
            info[:transfer_uris] += metric_uris

            results += metric_uris.map do |uri|
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
