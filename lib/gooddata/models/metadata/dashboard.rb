# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'dashboard_tab'
require_relative 'dashboard/filter_item'
require_relative 'dashboard/report_item'

require_relative '../../core/core'
require_relative '../../helpers/global_helpers'
require_relative '../metadata'
require_relative 'metadata'
require_relative 'report'

require 'multi_json'

module GoodData
  class Dashboard < GoodData::MdObject
    include Mixin::Lockable

    extend GoodData::Mixin::ContentPropertyReader
    extend GoodData::Mixin::ContentPropertyWriter

    content_property_reader :filters
    content_property_writer :filters


    EMPTY_OBJECT = {
      'projectDashboard' => {
        'content' => {
          'tabs' => [],
          'filters' => []
        },
        'meta' => {
          'tags' => '',
          'summary' => '',
          'title' => ''
        }
      }
    }

    ASSIGNABLE_MEMBERS = [
      :filters,
      :tabs,
      :tags,
      :summary,
      :title
    ]

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can
      # decide to pull in full objects. This is desirable from the
      # usability POV but unfortunately has negative impact on performance
      # so it is not the default.
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('projectDashboard', Dashboard, options)
      end

      def create(dashboard = {}, options = { :client => GoodData.client, :project => GoodData.project })
        client, project = GoodData.get_client_and_project(GoodData::Helpers.symbolize_keys(options))

        res = client.create(Dashboard, GoodData::Helpers.deep_dup(GoodData::Helpers.stringify_keys(EMPTY_OBJECT)), :project => project)
        dashboard.each do |k, v|
          res.send("#{k}=", v) if ASSIGNABLE_MEMBERS.include? k
        end
        res
      end
    end

    def add_tab(tab)
      new_tab = GoodData::DashboardTab.create(self, tab)
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
      x = client.post(
        req_uri,
        'clientExport' => {
          'url' => "#{client.connection.server_url}/dashboard.html#project=" \
                   "#{project.uri}&dashboard=#{uri}&tab=#{tab}&export=1",
          'name' => title
        }
      )
      client.poll_on_code(x['asyncTask']['link']['poll'], options.merge(process: false))
    end

    # Method used for replacing values in their state according to mapping.
    # Can be used to replace any values but it is typically used to replace
    # the URIs. Returns a new object of the same type.
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
