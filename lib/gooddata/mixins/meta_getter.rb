# encoding: UTF-8

require_relative 'data_getter'

module GoodData
  module Mixin
    module MetaGetter
      def meta
        data && data['meta']
      end
    end
  end
end
