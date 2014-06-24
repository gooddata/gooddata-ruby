# encoding: UTF-8

require 'erubis'
require 'multi_json'

require_relative '../metadata'
require_relative 'metadata'

# GoodData Module
module GoodData
  # Report Definition builder
  class ReportDefinitionBuilder
    class << self
      def create(metric, opts)
        args = {
          :metric => metric,
          :title => opts[:title] || 'Default Metric Title',
          :summary => opts[:summary] || ''
        }

        path = File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'report_definition', 'report_definition.json.erb')
        input = File.read(path)
        eruby = Erubis::Eruby.new(input)

        raw_json = eruby.result(args)
        json = MultiJson.load(raw_json)

        GoodData::ReportDefinition.new(json)
      end
    end
  end
end
