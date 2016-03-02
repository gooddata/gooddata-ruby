# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'dashboard_item'

module GoodData
  class FilterItem < DashboardItem
    EMPTY_OBJECT = {
      'filterItem' => {
        'positionX' => 0,
        'sizeY' => 200,
        'sizeX' => 300,
        'positionY' => 0
      }
    }

    ASSIGNABLE_MEMBERS = DashboardItem::ASSIGNABLE_MEMBERS + [
      :id,
      :content_id,
      :parent_filters
    ]

    class << self
      def create(tab, item)
        res = GoodData::FilterItem.new(tab, GoodData::Helpers.deep_dup(GoodData::Helpers.deep_stringify_keys(EMPTY_OBJECT)))
        item.each do |k, v|
          res.send("#{k}=", v) if ASSIGNABLE_MEMBERS.include? k
        end
        res
      end
    end

    def initialize(tab, json)
      super
    end

    def id
      data['id']
    end

    def id=(new_id)
      data['id'] = new_id
    end

    def content_id
      data['contentId']
    end

    def content_id=(new_content_id)
      data['contentId'] = new_content_id
    end

    def parent_filters
      data['parentFilters']
    end

    def parent_filters=(new_parent_filters)
      data['parentFilters'] = new_parent_filters
    end
  end
end
