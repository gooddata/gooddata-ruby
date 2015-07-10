# encoding: UTF-8

require_relative '../metadata'
require_relative '../../core/rest'
require_relative '../../mixins/is_fact'

require_relative 'metadata'

module GoodData
  class Fact < GoodData::MdObject
    root_key :fact

    include GoodData::Mixin::IsFact

    # TODO: verify that we have all (which we do not right now)
    FACT_BASE_AGGREGATIONS = [:sum, :min, :max, :avg, :median, :runsum, :runmin, :runmax, :runavg, :runstdev, :runstdevp, :runvar, :runvarp, :stdev, :stdevp, :var, :varp]

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('fact', Fact, options)
      end
    end

    # Creates the basic count metric with the fact used. The metric created is not saved.
    # @param [Hash] options the options to pass to the value list
    # @option options [Symbol] :type type of aggregation function. Default is :sum
    # @return [GoodData::Metric]
    def create_metric(options = { :type => :sum })
      a_type = options[:type] || :sum
      fail "Suggested aggreagtion function (#{a_type}) does not exist for base metric created out of fact. You can use only one of #{FACT_BASE_AGGREGATIONS.map { |x| ':' + x.to_s }.join(',')}" unless FACT_BASE_AGGREGATIONS.include?(a_type)
      a_title = options[:title] || "#{a_type} of #{title}"
      project.create_metric("SELECT #{a_type.to_s.upcase}([#{uri}])", title: a_title, extended_notation: false)
    end
  end
end
