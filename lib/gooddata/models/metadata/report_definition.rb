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
      def all(options = {})
        query('reportdefinition', ReportDefinition, options)
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
              GoodData::Attribute.new(x.json).display_forms.first
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

        unsaved_metrics = metrics.reject { |i| i.saved? }
        unsaved_metrics.each { |m| m.title = 'Untitled metric' unless m.title }

        begin
          unsaved_metrics.each { |m| m.save }
          rd = GoodData::ReportDefinition.create(options)
          data_result(execute_inline(rd, options), options)
        ensure
          unsaved_metrics.each { |m| m.delete if m && m.saved? }
        end
      end

      def execute_inline(rd, opts = { :client => GoodData.connection, :project => GoodData.project })
        client = opts[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        rd = rd.respond_to?(:json) ? rd.json : rd
        data = {
          report_req: {
            definitionContent: {
              content: rd,
              projectMetadata: project.links['metadata']
            }
          }
        }
        uri = "/gdc/app/projects/#{project.pid}/execute"

        client.post(uri, data)
      end

      # TODO: refactor the method. It should be instance method
      # Method used for getting a data_result from a wire representation of
      # @param result [Hash, Object] Wire data from JSON
      # @return [GoodData::ReportDataResult]
      def data_result(result, options = { :client => GoodData.connection })
        client = options[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        data_result_uri = result['execResult']['dataResult']
        result = client.get data_result_uri

        while result && result['taskState'] && result['taskState']['status'] == 'WAIT'
          sleep 10
          result = client.get data_result_uri
        end

        return nil unless result

        client.create(ReportDataResult, client.get(data_result_uri))
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

        left = ReportDefinition.find(left, options)
        top = ReportDefinition.find(top, options)

        # TODO: Put somewhere for i18n
        fail_msg = 'All metrics in report definition must be saved'
        fail fail_msg unless (left + top).all? { |i| i.saved? }

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
              'filters' => []
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

        client.create(ReportDefinition, pars, {:project => project})
      end
    end

    def metrics
      content['grid']['metrics'].map { |i| GoodData::Metric[i['uri']] }
    end

    def execute(opts = { :client => GoodData.connection, :project => GoodData.project })
      opts = {
        :client => client,
        :project => project
      }

      result = if saved?
                 pars = {
                   'report_req' => { 'reportDefinition' => uri }
                 }
                 client.post '/gdc/xtab2/executor', pars
               else
                 ReportDefinition.execute_inline(self, opts)
               end
      ReportDefinition.data_result(result, opts)
    end
  end
end
