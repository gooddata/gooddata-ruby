# encoding: UTF-8

require_relative '../metadata'
require_relative 'metadata'

module GoodData
  class DisplayForm < GoodData::MdObject
    root_key :attributeDisplayForm

    # Finds an attribute element URI for given value. This URI can be used by find_element_value to find the original value again
    # @param [String] value value of an label you are looking for
    # @return [String]
    def find_value_uri(value)
       value = CGI::escapeHTML(value)
       results = GoodData.post("#{uri}/validElements?limit=30&offset=0&order=asc&filter=#{value}", {})
       items = results['validElements']['items']
       if items.empty?
         fail "#{value} not found"
       else
         items.first['element']['uri']
       end
    end

    def find_element_value(element_id)
      element_id = element_id.is_a?(String) ? element_id.match(/\?id=(\d)/)[1] : element_id
      uri = links['elements']
      result = GoodData.get(uri + "/?id=#{element_id}")
      items = result['attributeElements']['elements']
      if items.empty?
        fail "Element id #{element_id} was not found"
      else
        items.first['title']
      end
    end

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
  end
end
