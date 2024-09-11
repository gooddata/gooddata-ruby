# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../metadata'
require_relative '../../mixins/is_label'
require_relative 'metadata'

module GoodData
  class Label < GoodData::MdObject
    include Mixin::IsLabel

    # Finds an attribute element URI for given value. This URI can be used by find_element_value to find the original value again
    # @param [String] value value of an label you are looking for
    # @return [String]
    def find_value_uri(value)
      results = get_valid_elements(filter: value)
      items = results['validElements']['items']
      if items.empty?
        fail(AttributeElementNotFound, value)
      else
        items.first['element']['uri']
      end
    end

    # For an element id find values (titles) for this label. Element id can be given as both number id or URI as a string beginning with /
    # @param [Object] element_id Element identifier either Number or a uri as a String
    # @return [String] value of the element if found
    def find_element_value(element_id)
      element_id = element_id.is_a?(String) ? element_id.match(/\?id=(\d+)/)[1] : element_id
      uri = links['elements']
      result = client.get(uri + "/?id=#{element_id}")
      items = result['attributeElements']['elements']
      if items.empty?
        fail(AttributeElementNotFound, element_id)
      else
        items.first['title']
      end
    end

    # Gets valid elements of a label for a specific paging (:offset and :limit) or get validElements of a specific value (:filter).
    # In the case filter a specific value, because the API /validElements only filter by partial match, we need to filter again at client side for exact match.
    # @return [Array] Results
    def get_valid_elements(*args)
      results = {}
      if args && !args.empty? && args.first[:filter]
        # Support paging in case filter by a specific value
        params = args.first
        all_valid_elements = []
        offset = 0
        paging_limit = 10_000

        loop do
          params[:offset] = offset
          params[:limit] = paging_limit
          results, = valid_elements params
          all_valid_elements << results['validElements']['items'].select do |i|
            i['element']['title'] == params[:filter]
          end

          if results['validElements']['items'].count < paging_limit
            results['validElements']['items'] = all_valid_elements
            break
          else
            offset += paging_limit
          end
        end
      else
        # This case will support paging by the method which call this method eg: values(...) method
        results, = valid_elements(*args)
      end
      results
    end

    # Finds if a label has an attribute element for given value.
    # @param [String] value value of an label you are looking for
    # @return [Boolean]
    def value?(value)
      find_value_uri(value)
      true
    rescue AttributeElementNotFound
      false
    end

    # Returns all values for this label. This is for inspection purposes only since obviously there can be huge number of elements.
    # @param [Hash] options the options to pass to the value list
    # @option options [Number] :limit limits the number of values to certain number. Default is 100
    # @return [Array]
    def values(options = {})
      all_values = []
      offset = options[:offset] || 0
      page_limit = options[:limit] || 100
      loop do
        results = get_valid_elements(limit: page_limit, offset: offset)

        elements = results['validElements']
        elements['items'].map do |el|
          v = el['element']
          all_values << {
            :value => v['title'],
            :uri => v['uri']
          }
        end
        break if elements['items'].count < page_limit

        offset += page_limit
      end
      all_values
    end

    def values_count
      results, = valid_elements
      count = GoodData::Helpers.get_path(results, %w(validElements paging total))
      count && count.to_i
    end

    # Gives an attribute of current label
    # @return [GoodData::Attibute]
    def attribute
      project.attributes(content['formOf'])
    end

    # Gives an attribute url of current label. Useful for mass actions when it does not introduce HTTP call.
    # @return [GoodData::Attibute]
    def attribute_uri
      content['formOf']
    end

    private

    def valid_elements(url_or_params = {}, request_payload = {})
      final_url = url_or_params

      if url_or_params.is_a?(Hash)
        default_params = {
          limit: 1,
          offset: 0,
          order: 'asc'
        }
        params = default_params.merge(url_or_params)
        query_params = params.map { |x, v| "#{x}=#{CGI.escape(v.to_s)}" }.reduce { |acc, elem| "#{acc}&#{elem}" }
        final_url = "#{uri}/validElements?#{query_params}"
      end

      results = client.post(final_url, 'validElementsRequest' => request_payload)

      # Implementation of polling is based on
      # https://opengrok.intgdc.com/source/xref/gdc-backend/src/test/java/com/gooddata/service/dao/ValidElementsDaoTest.java
      status_url = results['uri']
      if status_url
        results = client.poll_on_response(status_url) do |body|
          status = body['taskState'] && body['taskState']['status']
          status == 'RUNNING' || status == 'PREPARED' || body['uri']
        end
      end

      [results, params]
    end
  end
end

GoodData::DisplayForm = GoodData::Label
