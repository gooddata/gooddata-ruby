# encoding: UTF-8

require_relative '../metadata'

require_relative 'metadata'

require_relative '../../mixins/is_attribute'

module GoodData
  class Attribute < MdObject
    root_key :attribute

    include GoodData::Mixin::IsAttribute

    ATTRIBUTE_BASE_AGGREGATIONS = [:count]

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = {})
        query('attributes', Attribute, options)
      end

      # Finds the value of an atribute and gives you the textual form for the label that is acquired by calling primary_label method
      #
      # @param uri [String] Uri of the element. in the form of /gdc/md/PID/obj/OBJ_ID/elements?id=21
      # @return [String] Textual representation of a particular attribute element
      def find_element_value(uri)
        matches = uri.match(/(.*)\/elements\?id=(\d+)$/)
        Attribute[matches[1]].primary_label.find_element_value(uri)
      end
    end

    # Returns the labels of an attribute
    # @return [Array<GoodData::Label>]
    def display_forms
      content['displayForms'].map { |df| GoodData::Label[df['meta']['uri']] }
    end
    alias_method :labels, :display_forms

    # Returns the first display form which is the primary one
    # @return [GoodData::Label] Primary label
    def primary_display_form
      labels.first
    end
    alias_method :primary_label, :primary_display_form

    # Creates the basic count metric with the attribute used. If you need to compute the attribute on a different dataset you can specify that in params. The metric created is not saved.
    # @param [Hash] options the options to pass to the value list
    # @option options [Symbol] :type type of aggregation function.
    # @option options [Symbol] :attribute Use this attribute if you need to express different dataset for performing the computation on. It basically serves for creating metrics like SELECT COUNT(User, Opportunity).
    # @return [GoodData::Metric]
    def create_metric(options = {})
      an_attribute = options[:attribute]
      a_type = options[:type] || :count
      fail "Suggested aggreagtion function (#{a_type}) does not exist for base metric created out of attribute. You can use only one of #{ATTRIBUTE_BASE_AGGREGATIONS.map { |x| ":" + x.to_s }.join(',')}" unless ATTRIBUTE_BASE_AGGREGATIONS.include?(a_type)
      a_title = options[:title] || "#{a_type} of #{title}"
      if an_attribute
        Metric.xcreate(:expression => "SELECT #{a_type.to_s.upcase}(![#{identifier}], ![#{an_attribute.identifier}])", :title => a_title)
      else
        Metric.xcreate(:expression => "SELECT #{a_type.to_s.upcase}(![#{identifier}])", :title => a_title)
      end
    end

    # For an element id find values (titles) for all display forms. Element id can be given as both number id or URI as a string beginning with /
    # @param [Object] element_id Element identifier either Number or a uri as a String
    # @return [Array] list of values for certain element. Returned in the same order as is the order of labels
    def values_for(element_id)
      # element_id = element_id.is_a?(String) ? element_id.match(/\?id=(\d)/)[1] : element_id
      labels.map do |label|
        label.find_element_value(element_id)
      end
    end

    # Returns all values for all labels. This is for inspection purposes only since obviously there can be huge number of elements.
    # @param [Hash] options the options to pass to the value list
    # @option options [Number] :limit limits the number of values to certain number. Default is 100
    # @return [Array]
    def values(options = {})
      results = labels.map do |label|
        label.values(options)
      end
      results.first.zip(*results[1..-1])
    end

    # Allows to search in attribute labels by name. It uses the string as a basis for regexp and tries to match either a title or an identifier. Returns first match.
    # @param name [String] name used as a basis for regular expression
    # @return [GoodData::Label]
    def label_by_name(name)
      labels.find { |label| label.title.downcase =~ /#{name}/ || label.identifier.downcase =~ /#{name}/ }
    end
  end
end
