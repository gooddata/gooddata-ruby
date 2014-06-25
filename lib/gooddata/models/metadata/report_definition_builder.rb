# encoding: UTF-8

require 'erubis'
require 'multi_json'

require_relative '../metadata'
require_relative 'metadata'

require_relative '../../helpers/helpers'

# GoodData Module
module GoodData
  # Report Definition builder
  class ReportDefinitionBuilder
    DEFAULT_OPTS = {
      :type => 'headline'
    }

    class << self
      def construct_path(rel_path)
        File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'report_definition', rel_path)
      end

      def template_as_json(path, data)
        raw_json = GoodData::Helpers::Erb.template(construct_path(path), data)
        MultiJson.load(raw_json)
      end

      def create(metric, opts = DEFAULT_OPTS)
        opts = DEFAULT_OPTS.merge(opts)

        args = {
          :metric => metric,
          :title => opts[:title] || "Default Report Definition Title #{Time.new.strftime('%Y%m%d%H%M%S')}" ,
          :summary => opts[:summary] || ''
        }

        definition_json = template_as_json('report_definition.json.erb', args)
        definition_json['reportDefinition']['content']['chart'] = template_as_json("chart/#{opts[:type]}.json.erb", args)
        definition_json['reportDefinition']['meta'] = template_as_json('report_definition_meta.json.erb', args)

        GoodData::ReportDefinition.new(definition_json)
      end
    end
  end
end
