# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'dashboard_item'

module GoodData
  class GeoChartItem < DashboardItem
    EMPTY_OBJECT = {
      'geoChartItem' => {
        'positionX' => 0,
        'sizeY' => 200,
        'sizeX' => 300,
        'positionY' => 0
      }
    }

    ASSIGNABLE_MEMBERS = DashboardItem::ASSIGNABLE_MEMBERS + [
      :id,
      :metric,
      :layers_base_color
    ]

    class << self
      def create(tab, item)
        res = GoodData::GeoChartItem.new(tab, GoodData::Helpers.deep_dup(GoodData::Helpers.deep_stringify_keys(EMPTY_OBJECT)))
        item.each do |k, v|
          res.send("#{k}=", v) if ASSIGNABLE_MEMBERS.include? k
        end
        res
      end
    end

    def initialize(tab, json)
      super
    end

    def metric
      data['metric']
    end

    def metric=(new_metric)
      data['metric'] = new_metric.respond_to?(:uri) ? new_metric.uri : new_metric
    end

    def layers_base_color
      data['layersBaseColor']
    end

    def layers_base_color=(new_layers_base_color)
      data['layersBaseColor'] = new_layers_base_color
    end
  end
end
