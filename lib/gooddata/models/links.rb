module GoodData
  class Links < Hash
    def initialize(items)
      items['about']['links'].each do |item|
        self[item['category']] = item['link']
      end
    end
  end
end
