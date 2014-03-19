# encoding: UTF-8

module GoodData
  class Links
    attr_reader :data

    def initialize(items)
      @data = {}
      items.values[0]['links'].each do |item|
        category = item['category']
        if @data[category] then
          if @data[category]['category'] == category then
            @data[category] = {@data[category]['identifier'] => @data[category]}
          end
          @data[category][item['identifier']] = item
        else
          @data[category] = item
        end
      end
    end

    def links(category, identifier = nil)
      return Links.new(GoodData.get(self[category])) unless identifier
      Links.new GoodData.get(get(category, identifier))
    end

    def [](category)
      return @data[category]['link'] if @data[category] && @data[category]['link']
      @data[category]
    end

    def is_unique?(category)
      @data[category]['link'].is_a? String
    end

    def is_ambiguous?(category)
      !is_unique?(category)
    end

    def get(category, identifier)
      self[category][identifier]
    end
  end
end
