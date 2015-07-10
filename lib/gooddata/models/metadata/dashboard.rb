# encoding: UTF-8

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

      def create_report_tab(tab)
        title = tab[:title]
        {
          :title => title,
          :items => tab[:items].map { |i| GoodData::Dashboard.create_report_tab_item(i) }
        }
      end

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

    def exportable?
      true
    end

    def export(format, options = {})
      supported_formats = [:pdf]
      fail "Wrong format provied \"#{format}\". Only supports formats #{supported_formats.join(', ')}" unless supported_formats.include?(format)
      tab = options[:tab] || ''

      req_uri = "/gdc/projects/#{project.pid}/clientexport"
      x = client.post(req_uri, 'clientExport' => { 'url' => "https://secure.gooddata.com/dashboard.html#project=#{GoodData.project.uri}&dashboard=#{uri}&tab=#{tab}&export=1", 'name' => title })
      client.poll_on_code(x['asyncTask']['link']['poll'], options.merge(process: false))
    end

    def tabs
      content['tabs']
    end

    def tabs_ids
      tabs.map { |t| t['identifier'] }
    end
  end
end
