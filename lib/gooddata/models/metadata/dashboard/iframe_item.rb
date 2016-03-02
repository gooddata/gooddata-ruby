# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'dashboard_item'

module GoodData
  class IframeItem < DashboardItem
    EMPTY_OBJECT = {
      'textItem' => {
        'positionX' => 0,
        'sizeY' => 200,
        'sizeX' => 300,
        'positionY' => 0
      }
    }

    ASSIGNABLE_MEMBERS = DashboardItem::ASSIGNABLE_MEMBERS + [
      :url
    ]

    class << self
      def create(tab, item)
        res = GoodData::IframeItem.new(tab, GoodData::Helpers.deep_dup(GoodData::Helpers.deep_stringify_keys(EMPTY_OBJECT)))
        item.each do |k, v|
          res.send("#{k}=", v) if ASSIGNABLE_MEMBERS.include? k
        end
        res
      end
    end

    def initialize(tab, json)
      super
    end

    def url
      data['url']
    end

    def url=(new_url)
      data['url'] = new_url
    end
  end
end
