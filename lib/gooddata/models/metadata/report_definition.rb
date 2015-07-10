# encoding: UTF-8

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

      def create_metric_part(metric)
        {
          'alias' => metric.title,
          'uri' => metric.uri
        }
      end

      def create_attribute_part(attrib)
        {
          'attribute' => {
            'alias' => '',
            'totals' => [],
            'uri' => attrib.uri
          }
        }
      end

      def create_filters_part(filters)
        filters.select { |f| f.class == GoodData::Variable }.map do |v|
          { expression: "[#{v.uri}]" }
        end
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
        fail ArgumentError, 'No :client specified' if client.nil?

        stuff.map do |item|
          if item.respond_to?(:attribute?) && item.attribute?
            item.display_forms.first
          elsif item.is_a?(String)
            x = GoodData::MdObject.get_by_id(item, opts)
            fail "Object given by id \"#{item}\" could not be found" if x.nil?
            case x.raw_data.keys.first.to_s
            when 'attribute'
              attr = GoodData::Attribute.new(x.json)
              attr.client = client
              attr.project = opts[:project]
              attr.display_forms.first
            when 'attributeDisplayForm'
              GoodData::Label.new(x.json)
            when 'metric'
              GoodData::Metric.new(x.json)
            end
          elsif item.is_a?(Hash) && item.keys.include?(:title)
            case item[:type].to_s
            when 'metric'
              GoodData::Metric.find_first_by_title(item[:title])
            when 'attribute'
              result = GoodData::Attribute.find_first_by_title(item[:title])
              result.display_forms.first
            end
          elsif item.is_a?(Hash) && (item.keys.include?(:id))
            case item[:type].to_s
            when 'metric'
              GoodData::Metric.get_by_id(item[:id])
            when 'attribute'
              GoodData::Attribute.get_by_id(item[:id]).display_forms.first
            when 'label'
              GoodData::Label.get_by_id(item[:id])
          end
          elsif item.is_a?(Hash) && (item.keys.include?(:identifier))
            case item[:type].to_s
            when 'metric'
              GoodData::Metric.get_by_id(item[:identifier])
            when 'attribute'
              result = GoodData::Attribute.get_by_id(item[:identifier])
              result.display_forms.first
            when 'label'
              GoodData::Label.get_by_id(item[:identifier])
            end
          else
            item
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
              'filters' => ReportDefinition.create_filters_part(filters)
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
      data_result(result, opts)
    end

    def filters
      content['filters'].map { |f| f['expression'] }
    end

    # Replace certain object in report definition. Returns new definition which is not saved.
    #
    # @param what [GoodData::MdObject | String] Object which responds to uri or a string that should be replaced
    # @option for_what [GoodData::MdObject | String] Object which responds to uri or a string that should used as replacement
    # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
    def replace(what, for_what = nil)
      pairs = if what.is_a?(Hash)
                whats = what.keys
                to_whats = what.values
                whats.zip(to_whats)
              elsif what.is_a?(Array) && for_what.is_a?(Array)
                whats.zip(to_whats)
              else
                [[what, for_what]]
              end

      pairs.each do |pair|
        what = pair[0]
        for_what = pair[1]

        uri_what = what.respond_to?(:uri) ? what.uri : what
        uri_for_what = for_what.respond_to?(:uri) ? for_what.uri : for_what

        content['grid']['metrics'] = metric_parts.map do |item|
          item.deep_dup.tap do |i|
            i['uri'].gsub!("[#{uri_what}]", "[#{uri_for_what}]")
          end
        end

        cols = content['grid']['columns'] || []
        content['grid']['columns'] = cols.map do |item|
          if item.is_a?(Hash)
            item.deep_dup.tap do |i|
              i['attribute']['uri'].gsub!("[#{uri_what}]", "[#{uri_for_what}]")
            end
          else
            item
          end
        end

        rows = content['grid']['rows'] || []
        content['grid']['rows'] = rows.map do |item|
          if item.is_a?(Hash)
            item.deep_dup.tap do |i|
              i['attribute']['uri'].gsub!("[#{uri_what}]", "[#{uri_for_what}]")
            end
          else
            item
          end
        end

        widths = content['grid']['columnWidths'] || []
        content['grid']['columnWidths'] = widths.map do |item|
          if item.is_a?(Hash)
            item.deep_dup.tap do |i|
              if i['locator'][0].key?('attributeHeaderLocator')
                i['locator'][0]['attributeHeaderLocator']['uri'].gsub!("[#{uri_what}]", "[#{uri_for_what}]")
              end
            end
          else
            item
          end
        end

        sort = content['grid']['sort']['columns'] || []
        content['grid']['sort']['columns'] = sort.map do |item|
          if item.is_a?(Hash)
            item.deep_dup.tap do |i|
              next unless i.key?('metricSort')
              next unless i['metricSort'].key?('locators')
              next unless i['metricSort']['locators'][0].key?('attributeLocator2')
              i['metricSort']['locators'][0]['attributeLocator2']['uri'].gsub!("[#{uri_what}]", "[#{uri_for_what}]")
              i['metricSort']['locators'][0]['attributeLocator2']['element'].gsub!("[#{uri_what}]", "[#{uri_for_what}]")
            end
          else
            item
          end
        end

        if content.key?('chart')
          content['chart']['buckets'] = content['chart']['buckets'].reduce({}) do |a, e|
            key = e[0]
            val = e[1]
            a[key] = val.map do |item|
              item.deep_dup.tap do |i|
                i['uri'].gsub!("[#{uri_what}]", "[#{uri_for_what}]")
              end
            end
            a
          end
        end

        content['filters'] = filters.map { |filter_expression| { 'expression' => filter_expression.gsub("[#{uri_what}]", "[#{uri_for_what}]") } }
      end
      self
    end

    # Return true if the report definition is a table
    #
    # @return [Boolean] Return true if report definition is a table
    def table?
      content['format'] == 'grid'
    end

    private

    def data_result(result, options = {})
      data_result_uri = result['execResult']['dataResult']
      begin
        result = client.poll_on_response(data_result_uri, options) do |body|
          body && body['taskState'] && body['taskState']['status'] == 'WAIT'
        end
      rescue RestClient::BadRequest => e
        resp = JSON.parse(e.response)
        if GoodData::Helpers.get_path(resp, %w(error component)) == 'MD::DataResult'
          raise GoodData::UncomputableReport
        else
          raise e
        end
      end

      if result.empty?
        client.create(EmptyResult, result)
      else
        client.create(ReportDataResult, result)
      end
    end
  end
end
