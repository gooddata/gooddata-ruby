# encoding: UTF-8

require_relative '../metadata'
require_relative '../../mixins/is_label'
require_relative 'metadata'

module GoodData
  class Label < GoodData::MdObject
    root_key :attributeDisplayForm

    include GoodData::Mixin::IsLabel

    # Finds an attribute element URI for given value. This URI can be used by find_element_value to find the original value again
    # @param [String] value value of an label you are looking for
    # @return [String]
    def find_value_uri(value)
      escaped_value = CGI.escape(value)
      results = GoodData.post("#{uri}/validElements?limit=30&offset=0&order=asc&filter=#{escaped_value}", {})
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
        fail "Element id #{element_id} was not found"
      else
        items.first['title']
      end
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
      limit = options[:limit] || 100
      results = GoodData.post("#{uri}/validElements?limit=#{limit}&offset=0&order=asc", {})
      results['validElements']['items'].map do |el|
        v = el['element']
        {
          :value => v['title'],
          :uri => v['uri']
        }
      end
    end

    # Gives an attribute of current label
    # @return [GoodData::Attibute]
    def attribute
      GoodData::Attribute[content['formOf']]
    end

    # Gives an attribute url of current label. Useful for mass actions when it does not introduce HTTP call.
    # @return [GoodData::Attibute]
    def attribute_uri
      content['formOf']
    end
  end
end

GoodData::DisplayForm = GoodData::Label
