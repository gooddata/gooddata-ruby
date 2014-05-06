# encoding: UTF-8

require_relative '../metadata'
require_relative '../../core/rest'
require_relative 'metadata'

module GoodData
  class Fact < GoodData::MdObject
    root_key :fact

    # TODO: verify that we have all (which we do not right now)
    FACT_BASE_AGGREGATIONS = [:sum, :min, :max, :avg, :median]

    class << self
      def [](id, options = {})
        if id == :all
          facts = GoodData.get(GoodData.project.md['query'] + '/facts/')['query']['entries']
          options[:full] ? facts.map { |f| Fact[f['link']] } : facts
        else
          super
        end
      end
    end

    def fact?
      true
    end

    def create_metric(options = {})
      a_type = options[:type] || :sum
      fail "Suggested aggreagtion function (#{a_type}) does not exist for base metric created out of fact. You can use only one of #{FACT_BASE_AGGREGATIONS.map { |x| ":" + x.to_s }.join(',')}" unless FACT_BASE_AGGREGATIONS.include?(a_type)
      a_title = options[:title] || "#{a_type} of #{title}"
      Metric.xcreate(:expression => "SELECT #{a_type.to_s.upcase}(![#{identifier}])", :title => a_title)
    end
  end
end
