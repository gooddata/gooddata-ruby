# encoding: UTF-8

require File.join(File.dirname(__FILE__), 'metadata')

module GoodData
  class Dashboard < GoodData::MdObject
    root_key :projectDashboard

    class << self
      def [](id)
        if id == :all
          GoodData.get(GoodData.project.md['query'] + '/projectdashboards/')['query']['entries']
        else
          super
        end
      end

      def create_report_tab(tab)
        title = tab[:title]
        {
          :title => title,
          :items => tab[:items].map { |i| GoodData::Dashboard.create_report_tab_item(i) }
        }
      end

      def create_report_tab_item(options={})
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

      def create(options={})
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

    def export(format, options={})
      supported_formats = [:pdf]
      fail "Wrong format provied \"#{format}\". Only supports formats #{supported_formats.join(', ')}" unless supported_formats.include?(format)
      tab = options[:tab] || ''

      req_uri = "/gdc/projects/#{GoodData.project.uri}/clientexport"
      x = GoodData.post(req_uri, {'clientExport' => {'url' => "https://secure.gooddata.com/dashboard.html#project=#{GoodData.project.uri}&dashboard=#{uri}&tab=#{tab}&export=1", 'name' => title}}, :process => false)
      while (x.code == 202) do
        sleep(1)
        uri = JSON.parse(x.body)['asyncTask']['link']['poll']
        x = GoodData.get(uri, :process => false)
      end
      x
    end

    def tabs
      content['tabs']
    end

    def tabs_ids
      tabs.map { |t| t['identifier'] }
    end
  end
end
