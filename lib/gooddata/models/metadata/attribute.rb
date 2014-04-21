# encoding: UTF-8

require_relative 'metadata'

module GoodData
  class Attribute < MdObject
    root_key :attribute

    ATTRIBUTE_BASE_AGGREGATIONS = [:count]

    class << self
      def [](id)
        if id == :all
          GoodData.get(GoodData.project.md['query'] + '/attributes/')['query']['entries']
        else
          super
        end
      end
    end

    def display_forms
      content['displayForms'].map { |df| GoodData::DisplayForm[df['meta']['uri']] }
    end

    alias :labels :display_forms

    def is_attribute?
      true
    end

    def create_metric(options={})
      a_type = options[:type] || :sum
      fail "Suggested aggreagtion function (#{a_type}) does not exist for base metric created out of attribute. You can use only one of #{ATTRIBUTE_BASE_AGGREGATIONS.map {|x| ":" + x.to_s}.join(',')}" unless ATTRIBUTE_BASE_AGGREGATIONS.include?(a_type)
      a_title = options[:title] || "#{a_type} of #{title}"
      Metric.xcreate(:expression => "SELECT #{a_type.to_s.upcase}(![#{identifier}])", :title => a_title)
    end

  end
end