# encoding: UTF-8

module GoodData
  module Mixin
    module ContentGetterMixin
      def content
        data && data['content']
      end
    end
  end
end
