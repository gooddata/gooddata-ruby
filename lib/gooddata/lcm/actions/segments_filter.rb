# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SegmentsFilter < BaseAction
      DESCRIPTION = 'Filter Segments'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'Segments to provision'
        param :segments_filter, array_of(instance_of(Type::StringType)), required: false
      end

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          filtered_segments = params.segments
          if params.segments_filter
            segments_filter = params.segments_filter.map(&:downcase)

            filtered_segments = params.segments.select do |segment|
              segments_filter.include?(segment.segment_id.downcase)
            end
          end

          # Return results
          {
            results: filtered_segments,
            params: {
              segments: filtered_segments
            }
          }
        end
      end
    end
  end
end
