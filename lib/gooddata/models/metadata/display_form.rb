# encoding: UTF-8

require_relative '../metadata'
require_relative 'metadata'

module GoodData
  class DisplayForm < GoodData::MdObject
    root_key :attributeDisplayForm

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
      uri = links['elements']
      result = GoodData.get(uri + "/?id=#{element_id}")
      result['attributeElements']['elements'].first['title']
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

    def attribute
      GoodData::Attribute[content['formOf']]
    end
  end
end
