require 'pp'

module GoodData::Collections
  class Metadata < Hash
    def initialize(items)
      items['about']['links'].each do |item|
        self[item['title']] = item['link']
      end
    end
  end
end
