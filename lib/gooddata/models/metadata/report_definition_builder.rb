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
      :type => 'headline',
      :chart_format => 'chart'
    }

    TEMPLATES_DIR = File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'report_definition')

    CHART_TYPES = Dir.glob(File.join(TEMPLATES_DIR, '/chart/*/')).map { |f| File.basename(f) }

    class << self
      def construct_path(rel_path)
        File.join(TEMPLATES_DIR, rel_path)
      end

      def construct_rel_chart_path(name)
        "chart/#{name}/#{name}.json.erb"
      end

      def construct_rel_definition_path(name)
        "chart/#{name}/#{name}.definition.json.erb"
      end

      def template_as_json(path, data)
        raw_json = GoodData::Helpers::Erb.template(construct_path(path), data)
        MultiJson.load(raw_json)
      end

      def chart_types
        CHART_TYPES
      end

      def valid_chart?(chart)
        chart_types.include?(chart)
      end

      def create(metric, opts = DEFAULT_OPTS)
        opts = DEFAULT_OPTS.merge(opts)

        args = {
          :metric => metric,
          :title => opts[:title] || "Default Report Definition Title #{Time.new.strftime('%Y%m%d%H%M%S')}" ,
          :summary => opts[:summary] || '',
          :chart_format => opts[:chart_format]
        }

        definition_json = template_as_json('report_definition.json.erb', args)

        rel_path = construct_rel_definition_path(opts[:type])
        override_path = construct_path(rel_path)
        if File.exist? override_path
          override = template_as_json(rel_path, args)
          definition_json.deep_merge!(override)
        end

        definition_json['reportDefinition']['content']['chart'] = template_as_json(construct_rel_chart_path(opts[:type]), args)
        definition_json['reportDefinition']['content']['grid'] = template_as_json('report_definition_grid.json.erb', args)
        definition_json['reportDefinition']['meta'] = template_as_json('report_definition_meta.json.erb', args)
=begin
        {
          'reportDefinition' => {
            'content' => {
              'grid' => {
                'sort' => {
                  'columns' => [],
                  'rows' => []
                },
                'columnWidths' => [],
                'columns' => ReportDefinition.create_part(top),
                'metrics' => ReportDefinition.create_metrics_part(left, top),
                'rows' => ReportDefinition.create_part(left)
              },
              'format' => 'grid',
              'filters' => []
            },
            'meta' => {
              'tags' => '',
              'summary' => '',
              'title' => 'Untitled report definition'
            }
          }
        }
=end

        GoodData::ReportDefinition.new(definition_json)
      end
    end
  end
end
