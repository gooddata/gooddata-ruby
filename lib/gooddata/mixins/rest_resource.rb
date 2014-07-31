# encoding: UTF-8

require_relative 'root_key_setter'
require_relative 'data_property_reader'
require_relative 'data_property_writer'
require_relative 'meta_property_reader'
require_relative 'meta_property_reader'

module GoodData
  module Mixin
    module RestResource
      include GoodData::Mixin::RootKeySetter
      include GoodData::Mixin::DataPropertyReader
      include GoodData::Mixin::DataPropertyWriter
      include GoodData::Mixin::MetaPropertyReader
      include GoodData::Mixin::MetaPropertyWriter
    end
  end
end
