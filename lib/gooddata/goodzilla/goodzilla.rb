# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module SmallGoodZilla
    class << self
      # Scans the provided MAQL and returns Array pairs of [attribute, element] pairs for each element that is found in the definition
      # @param maql Input MAQL string
      # @return [Array<Array>] Pairs [attribute, attribute_element]
      def extract_element_uri_pairs(maql)
        arr = maql.scan(%r{\[([^\[\]]*)\/elements\?id=(\d+)\]}).flatten
        evens = arr.select.each_with_index { |_, i| i.even? }
        odds = arr.select.each_with_index { |_, i| i.odd? }.map(&:to_i)
        evens.zip(odds)
      end

      # Scans the provided MAQL and returns Array of all the URIs included in the MAQL. This basically return anything that is enclosed in aquare brackets []
      # @param maql Input MAQL string
      # @return [Array<String>] Pairs of URIs
      def get_uris(a_maql_string)
        a_maql_string.scan(/\[([^\"\]]+)\]/).flatten.uniq
      end

      # Get IDs from extendedMAQL string
      # @param a_maql_string Input MAQL string
      # @return [Array<String>] List of IDS
      def get_ids(a_maql_string)
        a_maql_string.scan(/!\[([^\"\]]+)\]/).flatten.uniq
      end

      # Get Facts from extendedMAQL string
      # @param a_maql_string Input MAQL string
      # @return [Array<String>] List of Facts
      def get_facts(a_maql_string)
        a_maql_string.scan(/#\"([^\"]+)\"/).flatten
      end

      # Get Attributes from extendedMAQL string
      # @param a_maql_string Input MAQL string
      # @return [Array<String>] List of Attributes
      def get_attributes(a_maql_string)
        a_maql_string.scan(/@\"([^\"]+)\"/).flatten
      end

      # Get Metrics from extendedMAQL string
      # @param a_maql_string Input MAQL string
      # @return [Array<String>] List of Metrics
      def get_metrics(a_maql_string)
        a_maql_string.scan(/\?"([^\"]+)\"/).flatten
      end

      alias_method :get_measures, :get_metrics

      # Method takes a specification of the attribute filter (category filter) and returns it representation that is
      # suitable for posting on the API. The spec is expected to be an array. First object can be an attribute (id, obj_id or
      # directly an object). Alternativel it can be an attribute (again any representation should work). In case of attribute
      # primary label is taken. The rest of the array are expected to be String represenation of values of particular label.
      #
      # For example it could look like
      # ['label.states.name', 'California', 'New Jersey', 'Kansas']
      #
      # @param spec [Array<Object>] Input MAQL string
      # @return [Array<Hash>] List of Metrics
      def create_category_filter(spec, project)
        item = project.objects(spec.first)
        label = item.is_a?(GoodData::Attribute) ? item.primary_label : item
        col = spec[1..-1].flat_map do |v|
          case v
          when Range
            v.to_a
          when Symbol
            [v]
          else
            [v.to_s]
          end
        end
        if col.first == :not
          values = col[1..-1].map { |v| label.find_value_uri(v) }
          elements = values.map { |v| "[#{v}]" }.join(', ')
          { expression: "[#{label.attribute.uri}] NOT IN (#{elements})" }
        else
          values = col.map { |v| label.find_value_uri(v) }
          elements = values.map { |v| "[#{v}]" }.join(', ')
          { expression: "[#{label.attribute.uri}] IN (#{elements})" }
        end
      end

      # Pretty prints the MAQL expression. This basically means it finds out names of objects and elements and print their values instead of URIs
      # @param expression [String] Expression to be beautified
      # @return [String] Pretty printed MAQL expression
      def pretty_print(expression, opts = { client: GoodData.connection, project: GoodData.project })
        temp = expression.dup
        pairs = get_uris(expression).pmap do |uri|
          if uri =~ /elements/
            begin
              [uri, Attribute.find_element_value(uri, opts)]
            rescue AttributeElementNotFound
              [uri, '(empty value)']
            end
          else
            [uri, GoodData::MdObject[uri, opts].title]
          end
        end
        pairs.each do |el|
          uri = el[0]
          obj = el[1]
          temp.sub!(uri, obj)
        end
        temp
      end

      def interpolate(values, dictionaries)
        {
          :facts => interpolate_values(values[:facts], dictionaries[:facts]),
          :attributes => interpolate_values(values[:attributes], dictionaries[:attributes]),
          :metrics => interpolate_values(values[:metrics], dictionaries[:metrics])
        }
      end

      def interpolate_ids(options, *ids)
        ids = ids.flatten
        if ids.empty?
          []
        else
          res = GoodData::MdObject.identifier_to_uri(options, *ids)
          fail 'Not all of the identifiers were resolved' if Array(res).size != ids.size
          res
        end
      end

      def interpolate_values(keys, values)
        x = values.values_at(*keys)
        keys.zip(x)
      end

      def interpolate_metric(metric, dictionary, options = { :client => GoodData.connection, :project => GoodData.project })
        interpolated = interpolate({
                                     :facts => GoodData::SmallGoodZilla.get_facts(metric),
                                     :attributes => GoodData::SmallGoodZilla.get_attributes(metric),
                                     :metrics => GoodData::SmallGoodZilla.get_metrics(metric)
                                   }, dictionary)

        ids = GoodData::SmallGoodZilla.get_ids(metric)
        interpolated_ids = ids.zip(Array(interpolate_ids(options, ids)))

        metric = interpolated[:facts].reduce(metric) { |a, e| a.sub("#\"#{e[0]}\"", "[#{e[1]}]") }
        metric = interpolated[:attributes].reduce(metric) { |a, e| a.sub("@\"#{e[0]}\"", "[#{e[1]}]") }
        metric = interpolated[:metrics].reduce(metric) { |a, e| a.sub("?\"#{e[0]}\"", "[#{e[1]}]") }
        metric = interpolated_ids.reduce(metric) { |a, e| a.gsub("![#{e[0]}]", "[#{e[1]}]") }
        metric
      end

      alias_method :interpolate_measure, :interpolate_metric
    end
  end
end
