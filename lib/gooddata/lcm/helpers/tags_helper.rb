# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module LCM2
    class Helpers
      class << self
        # @param Array of segments as in release brick parameters
        # @return Hash of segments and production tags
        # @example { { segment: 'tag1, tag1' } }
        def segment_production_tags(segments)
          return {} unless segments
          segments
            .reject { |s| s.production_tags.nil? }
            .map { |s| [s.segment_id, s.production_tags] }
            .to_h
        end

        # @param production_tags Global production tags
        # @param segment_production_tags Segment-specific production tags
        # @return Array of production tags
        # @example ['tag1', 'tag2']
        def parse_production_tags(production_tags, segment_production_tags)
          separator = ','
          tags = segment_production_tags || production_tags
          return [] unless tags
          tags = tags.split(separator).map(&:strip) unless tags.is_a?(Array)
          tags
        end
      end
    end
  end
end
