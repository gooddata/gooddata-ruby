module GoodData
  class Links < Hash
    def initialize(items)
      items['about']['links'].each do |item|
        self[item['category']] = item['link']
      end
    end

    def links(key)
      response = GoodData.get self[key]
      Links.new response
    end
  end
end
