# encoding: UTF-8

module GoodData
  module Mixin
    module Author
      # Gets Project Role Author
      #
      # @return [GoodData::Profile] Project Role author
      def author
        url = meta['author']
        tmp = GoodData.get url
        GoodData::Profile.new(tmp)
      end
    end
  end
end
