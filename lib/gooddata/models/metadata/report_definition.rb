# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../metadata'
require_relative 'metadata'

# GoodData Module
module GoodData
  # Report Definition
  # TODO: Add more doc ...
  class ReportDefinition < GoodData::MdObject
    root_key :reportDefinition

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('reportDefinition', ReportDefinition, options)
      end

      def create_metrics_part(left, top)
        stuff = Array(left) + Array(top)
        stuff.select { |item| item.respond_to?(:metric?) && item.metric? }.map do |metric|
          create_metric_part(metric)
        end
      end

      alias_method :create_measures_part, :create_metrics_part

      def create_metric_part(metric)
        {
          'alias' => metric.title,
          'uri' => metric.uri
        }
      end

      alias_method :create_measure_part, :create_metric_part

      def create_attribute_part(attrib)
        {
          'attribute' => {
            'alias' => '',
            'totals' => [],
            'uri' => attrib.uri
          }
        }
      end

      # Method creates the list of filter representaion suitable for posting on the api. It can currently recognize 2 types of filters. Variable filters and attribute filters. Method for internal usage
      #
      # @param filters [GoodData::Variable|Array<Array>]
      # @param options [Hash] the options hash
      # @return [Array<Hash>] Returns the structure that is stored internally in the report definition and later psted on the API
      def create_filters_part(filters, options = {})
        project = options[:project]
        vars = filters.select { |f| f.is_a?(GoodData::Variable) }.map { |v| { expression: "[#{v.uri}]" } }
        category = filters.select { |f| f.is_a?(Array) }.map { |v| GoodData::SmallGoodZilla.create_category_filter(v, project) }
        vars + category
      end

      def create_part(stuff)
        stuff = Array(stuff)
        parts = stuff.reduce([]) do |memo, item|
          if item.respond_to?(:metric?) && item.metric?
            memo
          else
            memo << create_attribute_part(item)
          end
          memo
        end
        if stuff.any? { |item| item.respond_to?(:metric?) && item.metric? }
          parts << 'metricGroup'
        end
        parts
      end

      def find(stuff, opts = { :client => GoodData.connection, :project => GoodData.project })
        client = opts[:client]
        project = opts[:project]
        fail ArgumentError, 'No :client specified' if client.nil?
        fail ArgumentError, 'No :project specified' if project.nil?

        stuff.map do |item|
          obj = if item.is_a?(String)
                  begin
                    project.objects(item)
                  rescue RestClient::ResourceNotFound
                    raise "Object given by id \"#{item}\" could not be found"
                  end
                elsif item.is_a?(Hash) && item.keys.include?(:title)
                  case item[:type].to_s
                  when 'metric'
                    GoodData::Metric.find_first_by_title(item[:title], opts)
                  when 'attribute'
                    GoodData::Attribute.find_first_by_title(item[:title], opts)
                  end
                elsif item.is_a?(Hash) && (item.keys.include?(:id) || item.keys.include?(:identifier))
                  id = item[:id] || item[:identifier]
                  case item[:type].to_s
                  when 'metric'
                    project.metrics(id)
                  when 'attribute'
                    project.attributes(id)
                  when 'label'
                    projects.labels(id)
                  end
                else
                  item
                end
          if obj.respond_to?(:attribute?) && obj.attribute?
            obj.display_forms.first
          else
            obj
          end
        end
      end

      def execute(options = {})
        left = Array(options[:left])
        top = Array(options[:top])

        metrics = (left + top).select { |item| item.respond_to?(:metric?) && item.metric? }

        unsaved_metrics = metrics.reject(&:saved?)
        unsaved_metrics.each { |m| m.title = 'Untitled metric' unless m.title }

        begin
          unsaved_metrics.each(&:save)
          GoodData::ReportDefinition.create(options).execute
        ensure
          unsaved_metrics.each { |m| m.delete if m && m.saved? }
        end
      end

      def create(options = { :client => GoodData.connection, :project => GoodData.project })
        client = options[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = options[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, options]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        left = Array(options[:left])
        top = Array(options[:top])
        filters = options[:filters] || []

        left = ReportDefinition.find(left, options)
        top = ReportDefinition.find(top, options)

        # TODO: Put somewhere for i18n
        fail_msg = 'All metrics in report definition must be saved'
        fail fail_msg unless (left + top).all?(&:saved?)

        pars = {
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
              'filters' => ReportDefinition.create_filters_part(filters, :project => p)
            },
            'meta' => {
              'tags' => '',
              'summary' => '',
              'title' => 'Untitled report definition'
            }
          }
        }
        # TODO: write test for report definitions with explicit identifiers
        pars['reportDefinition']['meta']['identifier'] = options[:identifier] if options[:identifier]

        client.create(ReportDefinition, pars, :project => project)
      end
    end

    def attribute_parts
      cols = content['grid']['columns'] || []
      rows = content['grid']['rows'] || []
      items = cols + rows
      items.select { |item| item.is_a?(Hash) && item.keys.first == 'attribute' }
    end

    def attributes
      labels.map(&:attribute)
    end

    # Removes the color mapping from report definition
    #
    # @return [GoodData::ReportDefinition] Returns self
    def reset_color_mapping!
      global_chart_options = GoodData::Helpers.get_path(content, %w(chart styles global))
      global_chart_options['colorMapping'] = [] if global_chart_options
      self
    end

    # Return true if the report definition is a chart
    #
    # @return [Boolean] Return true if report definition is a chart
    def chart?
      !table?
    end

    def labels
      attribute_parts.map { |part| project.labels(part['attribute']['uri']) }
    end

    def metric_parts
      content['grid']['metrics']
    end

    alias_method :measure_parts, :metric_parts

    def metrics
      metric_parts.map { |i| project.metrics(i['uri']) }
    end

    def execute(opts = {})
      result = if saved?
                 pars = {
                   'report_req' => { 'reportDefinition' => uri }
                 }
                 client.post '/gdc/xtab2/executor3', pars
               else
                 data = {
                   report_req: {
                     definitionContent: {
                       content: to_hash,
                       projectMetadata: project.links['metadata']
                     }
                   }
                 }
                 uri = "/gdc/app/projects/#{project.pid}/execute"
                 client.post(uri, data)
               end
      GoodData::Report.data_result(result, opts.merge(client: client))
    end

    def filters
      content['filters'].map { |f| f['expression'] }
    end

    # Method used for replacing values in their state according to mapping. Can be used to replace any values but it is typically used to replace the URIs. Returns a new object of the same type.
    #
    # @param [Array<Array>]Mapping specifying what should be exchanged for what. As mapping should be used output of GoodData::Helpers.prepare_mapping.
    # @return [GoodData::ReportDefinition]
    def replace(mapping)
      x = GoodData::MdObject.replace_quoted(self, mapping)
      x = GoodData::MdObject.replace_bracketed(x, mapping)
      vals = GoodData::MdObject.find_replaceable_values(self, mapping)
      GoodData::MdObject.replace_bracketed(x, vals)
    end

    # Return true if the report definition is a table
    #
    # @return [Boolean] Return true if report definition is a table
    def table?
      content['format'] == 'grid'
    end
  end
end
