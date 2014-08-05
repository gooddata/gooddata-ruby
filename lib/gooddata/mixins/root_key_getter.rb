# encoding: UTF-8

module GoodData
  module Mixin
    module RootKeyGetter
      def root_key
        json.keys.first
      end
    end
  end
end
