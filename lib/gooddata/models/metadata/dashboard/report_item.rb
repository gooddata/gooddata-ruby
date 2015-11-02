# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'dashboard_item'
require_relative '../../../helpers/global_helpers'

module GoodData
  class ReportItem < DashboardItem
    EMPTY_OBJECT = {
      :reportItem => {
        :obj => nil,
        :sizeY => 200,
        :sizeX => 300,
        :style => {
          :displayTitle => 1,
          :background => {
            :opacity => 0
          }
        },
        :visualization => {
          :grid => {
            :columnWidths => []
          },
          :oneNumber => {
            :labels => {}
          }
        },
        :positionY => 0,
        :filters => [],
        :positionX => 0
      }
    }

    ASSIGNABLE_MEMBERS = DashboardItem::ASSIGNABLE_MEMBERS + [
      :filters,
      :obj,
      :report,
      :style,
      :visualization
    ]

    class << self
      def obj_uri(obj)
        obj.respond_to?(:uri) ? obj.uri : obj
      end

      def create(tab, item)
        res = GoodData::ReportItem.new(tab, GoodData::Helpers.deep_dup(GoodData::Helpers.deep_stringify_keys(EMPTY_OBJECT)))
        item.each do |k, v|
          res.send("#{k}=", v) if ASSIGNABLE_MEMBERS.include? k
        end
        res
      end
    end

    def initialize(tab, json)
      super
    end

    def obj
      GoodData::MdObject[data['obj'], :client => tab.dashboard.client, :project => tab.dashboard.project]
    end

    alias_method :object, :obj

    def obj=(new_obj)
      data['obj'] = ReportItem.obj_uri(new_obj)
    end

    alias_method :object=, :obj=
    alias_method :report=, :obj=

    def style
      data['style']
    end

    def style=(new_style)
      data['style'] = new_style
    end

    def visualization
      data['visualization']
    end

    def visualization=(new_visualization)
      data['visualization'] = new_visualization
    end
  end
end
