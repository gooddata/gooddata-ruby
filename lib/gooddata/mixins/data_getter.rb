# encoding: UTF-8

module GoodData
  module Mixin
    module DataGetter
      def data
        json[root_key]
      end
    end
  end
end
