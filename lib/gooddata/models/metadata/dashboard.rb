# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'dashboard_tab'
require_relative 'dashboard/filter_item'
require_relative 'dashboard/report_item'

require_relative '../../core/core'
require_relative '../metadata'
require_relative 'metadata'
require_relative 'report'

require 'multi_json'

module GoodData
  class Dashboard < GoodData::MdObject
    root_key :projectDashboard

    include GoodData::Mixin::Lockable

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('projectDashboard', Dashboard, options)
      end

      def create_report_tab(tab, options = { :client => GoodData.client, :project => GoodData.project })
        title = tab[:title]
        {
          :title => title,
          :items => tab[:items].map { |i| GoodData::Dashboard.create_report_tab_item(i, options) }
        }
      end

      def create_report_tab_item(item, options = { :client => GoodData.client, :project => GoodData.project })
        title = item[:title]

        report = GoodData::Report.find_first_by_title(title, options)
        {
          :reportItem => {
            :obj => report.uri,
            :sizeY => item[:size_y] || 200,
            :sizeX => item[:size_x] || 300,
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
            :positionY => item[:position_y] || 0,
            :filters => [],
            :positionX => item[:position_x] || 0
          }
        }
      end

      def create(dashboard = { :tabs => [] }, options = { :client => GoodData.client, :project => GoodData.project })
        client = options[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = options[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, options]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        tabs = dashboard[:tabs] || []

        stuff = {
          'projectDashboard' => {
            'content' => {
              'tabs' => tabs.map { |t| GoodData::Dashboard.create_report_tab(t, options) },
              'filters' => []
            },
            'meta' => {
              'tags' => dashboard[:tags],
              'summary' => dashboard[:summary],
              'title' => dashboard[:title]
            }
          }
        }

        client.create(Dashboard, stuff, :project => project)
      end
    end

    def add_tab(tab)
      title = tab[:title] || 'Default Tab Title'
      items = tab[:items] || []

      new_tab_json = {
        :title => title,
        :items => items.map { |i| GoodData::Dashboard.create_report_tab_item(i, options) }
      }

      new_tab = GoodData::DashboardTab.new(self, GoodData::Helpers.deep_stringify_keys(new_tab_json))
      content['tabs'] << new_tab.json
      new_tab
    end

    alias_method :create_tab, :add_tab

    def exportable?
      true
    end

    def export(format, options = {})
      supported_formats = [:pdf]
      fail "Wrong format provied \"#{format}\". Only supports formats #{supported_formats.join(', ')}" unless supported_formats.include?(format)
      tab = options[:tab] || ''

      req_uri = "/gdc/projects/#{project.pid}/clientexport"
      x = client.post(req_uri, 'clientExport' => { 'url' => "#{client.connection.server_url}/dashboard.html#project=#{GoodData.project.uri}&dashboard=#{uri}&tab=#{tab}&export=1", 'name' => title })
      client.poll_on_code(x['asyncTask']['link']['poll'], options.merge(process: false))
    end

    # Method used for replacing values in their state according to mapping. Can be used to replace any values but it is typically used to replace the URIs. Returns a new object of the same type.
    #
    # @param [Array<Array>]Mapping specifying what should be exchanged for what. As mapping should be used output of GoodData::Helpers.prepare_mapping.
    # @return [GoodData::Dashboard]
    def replace(mapping)
      x = GoodData::MdObject.replace_quoted(self, mapping)
      vals = GoodData::MdObject.find_replaceable_values(self, mapping)
      GoodData::MdObject.replace_quoted(x, vals)
    end

    def tabs
      content['tabs'].map do |tab|
        GoodData::DashboardTab.new(self, tab)
      end
    end

    def tabs_ids
      tabs.map { |t| t['identifier'] }
    end
  end
end
