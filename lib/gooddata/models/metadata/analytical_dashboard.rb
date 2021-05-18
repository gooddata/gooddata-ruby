# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'analytical_visualization_object'

module GoodData
  class AnalyticalDashboard < GoodData::AnalyticalVisualizationObject
    EMPTY_OBJECT = {
      'analyticalDashboard' => {
        'content' => {
          'filterContext' => '',
          'layout' => {},
          'widgets' => []
        },
        'meta' => {
          'deprecated' => '0',
          'summary' => '',
          'title' => ''
        }
      }
    }

    ASSIGNABLE_MEMBERS = %i[filterContext layout widgets deprecated summary title]

    class << self
      # Method intended to get all AnalyticalDashboard objects in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full with true value will pull in full objects. Default is false value
      # @return [Array<GoodData::AnalyticalDashboard>] Return AnalyticalDashboard list
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('analyticalDashboard', AnalyticalDashboard, options)
      end

      # Create Analytical Dashboard in the specify project
      #
      # @param analytical_dashboard [Hash] the data of object will be created
      # @param options [Hash] The project that the object will be created in
      # @return GoodData::AnalyticalDashboard object
      def create(analytical_dashboard = {}, options = { :client => GoodData.client, :project => GoodData.project })
        GoodData::AnalyticalVisualizationObject.create(analytical_dashboard, AnalyticalDashboard, EMPTY_OBJECT, ASSIGNABLE_MEMBERS, options)
      end
    end
  end
end
