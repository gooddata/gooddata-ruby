# encoding: UTF-8

require_relative '../rest/object'

module GoodData
  class Links < GoodData::Rest::Object
    attr_reader :data

    def initialize(items)
      @data = {}
      items.values[0]['links'].each do |item|
        category = item['category']
        if @data[category]
          if @data[category]['category'] == category
            @data[category] = { @data[category]['identifier'] => @data[category] }
          end
          @data[category][item['identifier']] = item
        else
          @data[category] = item
        end
      end
    end

    def links(category, identifier = nil)
      return Links.new(client.get(self[category])) unless identifier
      Links.new client.get(get(category, identifier))
    end

    def [](category)
      return @data[category]['link'] if @data[category] && @data[category]['link']
      @data[category]
    end

    def unique?(category)
      @data[category]['link'].is_a? String
    end

    def ambiguous?(category)
      !unique?(category)
    end

    def get(category, identifier)
      self[category][identifier]
    end
  end
end
