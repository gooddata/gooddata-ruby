# encoding: UTF-8

module GoodData
  module Mixin
    module ContentGetter
      def content
        data && data['content']
      end
    end
  end
end
