# encoding: UTF-8

require_relative 'data_getter'
require_relative 'meta_getter'

module GoodData
  module Mixin
    module RestGetters
      include GoodData::Mixin::MetaGetter
      include GoodData::Mixin::DataGetter
    end
  end
end
