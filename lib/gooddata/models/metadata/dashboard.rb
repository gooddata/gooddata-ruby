# encoding: UTF-8

require_relative '../../core/core'
require_relative '../metadata'
require_relative 'metadata'
require_relative 'report'

require 'multi_json'

module GoodData
  class Dashboard < GoodData::MdObject
    root_key :projectDashboard

    class << self
      def resource_name
        'projectDashboard'
      end

      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = {})
        query('projectdashboards', Dashboard, options)
      end

      # TODO: Merge with GoodData::DashboardBuilder
      def create_report_tab(tab)
        title = tab[:title]
        {
          :title => title,
          :items => tab[:items].map { |i| GoodData::Dashboard.create_report_tab_item(i) }
        }
      end

      alias_method :add_tab, :create_report_tab

      # TODO: Merge with GoodData::DashboardBuilder
      def create_report_tab_item(options = {})
        title = options[:title]

        report = GoodData::Report.find_first_by_title(title)
        {
          :reportItem => {
            :obj => report.uri,
            :sizeY => options[:size_y] || 200,
            :sizeX => options[:size_x] || 300,
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
            :positionY => options[:position_y] || 0,
            :filters => [],
            :positionX => options[:position_x] || 0
          }
        }
      end

      # TODO: Obsolete by GoodData::DashboardBuilder
      def create(options = {})
        stuff = {
          'projectDashboard' => {
            'content' => {
              'tabs' => options[:tabs].map { |t| GoodData::Dashboard.create_report_tab(t) },
              'filters' => []
            },
            'meta' => {
              'tags' => options[:tags],
              'summary' => options[:summary],
              'title' => options[:title]
            }
          }
        }
        Dashboard.new(stuff)
      end
    end

    def add_tab(tab)
      json = GoodData::Model::TabBuilder.create(self, tab).to_hash
      content['tabs'] << json
    end

    def delete
      super
    end

    def exportable?
      true
    end

    def export(format, options = {})
      supported_formats = [:pdf]
      fail "Wrong format provied \"#{format}\". Only supports formats #{supported_formats.join(', ')}" unless supported_formats.include?(format)
      tab = options[:tab] || ''

      req_uri = "/gdc/projects/#{GoodData.project.uri}/clientexport"
      x = GoodData.post(req_uri, { 'clientExport' => { 'url' => "https://secure.gooddata.com/dashboard.html#project=#{GoodData.project.uri}&dashboard=#{uri}&tab=#{tab}&export=1", 'name' => title } }, :process => false)
      while x.code == 202
        sleep(1)
        uri = MultiJson.load(x.body)['asyncTask']['link']['poll']
        x = GoodData.get(uri, :process => false)
      end
      x
    end

    def remove_report(report)
      tabs.each do |tab|
        new_items = tab.items.select do |x|
          x.uri != report['link']
        end

        tab.items = new_items.map { |x| x.json }
      end

      save
    end

    def remove_tab(tab_name)
      content['tabs'] = content['tabs'].select do |tab|
        tab.title != tab_name
      end
    end

    # Gets dashboard tab by its name
    # @param name Dashboard tab name
    # @return GoodData::Dashboard::Tab Dashboard tab instance
    def tab(name)
      return name if name.kind_of?(GoodData::Dashboard::Tab)
      fail ArgumentError, 'Invalid type of argument name, should be String or GoodData::Dashboard::Tab' unless name.kind_of?(String)

      tabs.each do |tab|
        return tab if tab.title == name
      end
      nil
    end

    # Gets all dashboard tabs
    # @return [Array<GoodData::Dashboard::Tab>] Array of tabs belonging to dashboard
    def tabs
      content['tabs'].map do |tab|
        GoodData::Dashboard::Tab.new(self, tab)
      end
    end

    # Gets IDs of all dashboard tabs
    # @return [Array<String>] List if dashboard tab identifiers
    def tabs_ids
      tabs.map { |t| t['identifier'] }
    end
  end
end
