# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'analytical_visualization_object'

module GoodData
  class VisualizationObject < GoodData::AnalyticalVisualizationObject
    EMPTY_OBJECT = {
      'visualizationObject' => {
        'content' => {
          'buckets' => [],
          'properties' => '',
          'visualizationClass' => {}
        },
        'links' => {},
        'meta' => {
          'deprecated' => '0',
          'summary' => '',
          'title' => ''
        }
      }
    }

    ASSIGNABLE_MEMBERS = %i[buckets properties visualizationClass deprecated summary title]

    class << self
      # Method intended to get all VisualizationObject objects in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full with true value to pull full objects
      # @return [Array<GoodData::VisualizationObject>] Return VisualizationObject list
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('visualizationObject', VisualizationObject, options)
      end

      # Create Visualization Object in the specify project
      #
      # @param visualization_object [Hash] the data of object will be created
      # @param options [Hash] The project that the object will be created in
      # @return GoodData::VisualizationObject object
      def create(visualization_object = {}, options = { :client => GoodData.client, :project => GoodData.project })
        GoodData::AnalyticalVisualizationObject.create(visualization_object, VisualizationObject, EMPTY_OBJECT, ASSIGNABLE_MEMBERS, options)
      end
    end
  end
end
