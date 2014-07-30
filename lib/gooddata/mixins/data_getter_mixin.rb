# encoding: UTF-8

module GoodData
  module Mixin
    module DataGetterMixin
      def data
        json[root_key]
      end
    end
  end
end
