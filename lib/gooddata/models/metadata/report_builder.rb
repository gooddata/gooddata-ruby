# encoding: UTF-8

require 'erubis'
require 'multi_json'

require_relative '../metadata'
require_relative 'metadata'

# GoodData Module
module GoodData
  # Report Definition builder
  class ReportBuilder
    class << self
      def create(definition, opts = {})
        args = {
          :title => opts[:title] || "Default Report Title #{Time.new.strftime('%Y%m%d%H%M%S')}",
          :summary => opts[:summary] || '',
          :definition => definition
        }

        path = File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'report', 'report.json.erb')
        input = File.read(path)
        eruby = Erubis::Eruby.new(input)

        raw_json = eruby.result(args)
        json = MultiJson.load(raw_json)

        GoodData::Report.new(json)
      end
    end
  end
end
