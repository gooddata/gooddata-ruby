# encoding: UTF-8

require_relative '../../goodzilla/goodzilla'
require_relative '../metadata'
require_relative 'metadata'

module GoodData
  # Metric representation
  class Metric < MdObject
    root_key :metric

    PARSE_MAQL_OBJECT_REGEXP = /\[([^\]]+)\]/

    class << self
      def [](id, options = {})
        if id == :all
          metrics = GoodData.get(GoodData.project.md['query'] + '/metrics/')['query']['entries']
          options[:full] ? metrics.map { |m| Metric[m['link']] } : metrics
        else
          super
        end
      end

      def xcreate(options)
        if options.is_a?(String)
          create(:expression => options, :extended_notation => true)
        else
          create(options.merge(:extended_notation => true))
        end
      end

      def create(options = {})
        if options.is_a?(String)
          expression = options
          extended_notation = false
          title = nil
        else
          title = options[:title]
          summary = options[:summary]
          expression = options[:expression] || fail('Metric has to have its expression defined')
          extended_notation = options[:extended_notation] || false
        end

        expression = if extended_notation
                       dict = {
                         :facts => GoodData::Fact[:all].reduce({}) do |memo, item|
                           memo[item['title']] = item['link']
                           memo
                         end,
                         :attributes => GoodData::Attribute[:all].reduce({}) do |memo, item|
                           memo[item['title']] = item['link']
                           memo
                         end,
                         :metrics => GoodData::Metric[:all].reduce({}) do |memo, item|
                           memo[item['title']] = item['link']
                           memo
                         end
                       }
                       interpolated_metric = GoodData::SmallGoodZilla.interpolate_metric(expression, dict)
                       interpolated_metric
                     else
                       expression
                     end

        metric = {
          'metric' => {
            'content' => {
              'format' => '#,##0',
              'expression' => expression
            },
            'meta' => {
              'tags' => '',
              'summary' => summary,
              'title' => title
            }
          }
        }
        # TODO: add test for explicitly provided identifier
        metric['metric']['meta']['identifier'] = options[:identifier] if options[:identifier]
        Metric.new(metric)
      end

      def execute(expression, options = {})
        m = if expression.is_a?(String)
              GoodData::Metric.create({ :title => 'Temporary metric to be deleted', :expression => expression }.merge(options))
            else
              GoodData::Metric.create({ :title => 'Temporary metric to be deleted' }.merge(expression))
            end
        m.execute
      end

      def xexecute(expression)
        if expression.is_a?(String)
          execute(:expression => expression, :extended_notation => true)
        else
          execute(expression.merge(:extended_notation => true))
        end
      end
    end

    def execute
      res = GoodData::ReportDefinition.execute(:left => self)
      res[0][0]
    end

    def expression
      content['expression']
    end

    def expression=(value)
      content['expression'] = value
    end

    def validate
      fail 'Meric needs to have title' if title.nil?
      true
    end

    def metric?
      true
    end

    # Checks that the expression contains certain metadata object. The difference between this and used_by using is in the fact that this is not a transitive closure. it searches only inside the expression
    # @param [GoodData::MdObject] item Object that is going to be looked up
    # @return [Boolean]
    def contain?(item)
      uri = item.respond_to?(:uri) ? item.uri : item
      expression[uri] != nil
    end

    # Checks that the expression contains certain element of an attribute. The value is looked up through given label.
    # @param [GoodData::DisplayForm] label Label though which the value is looked up
    # @param [String] value Value that will be looked up through the label.
    # @return [Boolean]
    def cantain_value?(label, value)
      uri = label.find_value_uri(label, value)
      contain?(uri)
    end

    # Method used for replacing objects like Attribute, Fact or Metric.
    # @param [GoodData::MdObject] what Object that should be replaced
    # @param [GoodData::MdObject] for_what Object it is replaced with
    # @return [GoodData::Metric]
    def replace(what, for_what)
      uri_what = what.respond_to?(:uri) ? what.uri : what
      uri_for_what = for_what.respond_to?(:uri) ? for_what.uri : for_what
      self.expression = expression.gsub(uri_what, uri_for_what)
      self
    end

    # Method used for replacing attribute element values. Looks up certain value of a label in the MAQL expression and exchanges it for a different value of the same label.
    # @param [GoodData::DisplayForm] label Label through which the value and for_value are resolved
    # @param [String] value value that is going to be replaced
    # @param [String] for_value value that is going to be the new one
    # @return [GoodData::Metric]
    def replace_value(label, value, for_value)
      label = label.respond_to?(:primary_label) ? label.primary_label : label
      value_uri = label.find_value_uri(value)
      for_value_uri = label.find_value_uri(for_value)
      self.expression = expression.gsub(value_uri, for_value_uri)
      self
    end

    # Looks up the readable values of the objects used inside of MAQL epxpressions. Labels and elements titles are based on the primary label.
    # @return [String] Ther resulting MAQL like expression
    def pretty_expression
      temp = expression.dup
      expression.scan(PARSE_MAQL_OBJECT_REGEXP).each do |uri|
        uri = uri.first
        if uri =~ /elements/
          temp.sub!(uri, Attribute.find_element_value(uri))
        else
         obj = GoodData::MdObject[uri]
          temp.sub!(uri, obj.title)
        end
      end
      temp
    end
  end
end
