# encoding: UTF-8

module GoodData
  module Mixin
    module MetaGetterMixin
      def meta
        data && data['meta']
      end
    end
  end
end
