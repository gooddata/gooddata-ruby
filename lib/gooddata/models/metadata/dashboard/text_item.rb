# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'dashboard_item'

module GoodData
  class TextItem < DashboardItem
    EMPTY_OBJECT = {
      'textItem' => {
        'positionX' => 0,
        'sizeY' => 200,
        'sizeX' => 300,
        'positionY' => 0
      }
    }

    ASSIGNABLE_MEMBERS = DashboardItem::ASSIGNABLE_MEMBERS + [
      :text,
      :text_size
    ]

    class << self
      def create(tab, item)
        res = GoodData::TextItem.new(tab, GoodData::Helpers.deep_dup(GoodData::Helpers.deep_stringify_keys(EMPTY_OBJECT)))
        item.each do |k, v|
          res.send("#{k}=", v) if ASSIGNABLE_MEMBERS.include? k
        end
        res
      end
    end

    def initialize(tab, json)
      super
    end

    def text
      data['text']
    end

    def text=(new_text)
      data['text'] = new_text
    end

    def text_size
      data['textSize']
    end

    def text_size=(new_text_size)
      data['textSize'] = new_text_size
    end
  end
end
