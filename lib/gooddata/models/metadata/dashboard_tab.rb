# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../../core/core'
require_relative '../../helpers/global_helpers'
require_relative '../metadata'
require_relative 'metadata'
require_relative 'report'

require 'multi_json'

module GoodData
  class DashboardTab
    attr_reader :dashboard
    attr_accessor :json

    EMPTY_OBJECT = {
      :title => '',
      :items => []
    }

    ASSIGNABLE_MEMBERS = [
      :title,
      :items,
      :identifier
    ]

    class << self
      def create(dashboard, tab)
        res = GoodData::DashboardTab.new(dashboard, GoodData::Helpers.deep_dup(GoodData::Helpers.deep_stringify_keys(EMPTY_OBJECT)))
        tab.each do |k, v|
          res.send("#{k}=", v) if ASSIGNABLE_MEMBERS.include? k
        end
        res
      end
    end

    def initialize(dashboard, json)
      @dashboard = dashboard
      @json = json
    end

    def create_report_item(item)
      new_item = GoodData::ReportItem.create(self, item)
      self.json['items'] << new_item.json
      new_item
    end
    alias_method :add_report_item, :create_report_item

    def identifier
      @json['identifier']
    end

    def identifier=(new_identifier)
      @json['identifier'] = new_identifier
    end

    def items
      @json['items'].map do |item|
        type = item.keys.first
        case type
        when 'reportItem'
          GoodData::ReportItem.new(self, item)
        when 'filterItem'
          GoodData::FilterItem.new(self, item)
        else
          GoodData::DashboardItem.new(self, item)
        end
      end
    end

    def title
      @json['title']
    end

    def title=(new_title)
      @json['title'] = new_title
    end
  end
end
