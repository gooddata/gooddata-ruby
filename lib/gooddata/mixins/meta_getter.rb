# encoding: UTF-8

module GoodData
  module Mixin
    module MetaGetter
      def meta
        data && data['meta']
      end
    end
  end
end
