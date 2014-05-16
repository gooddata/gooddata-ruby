# encoding: UTF-8

require_relative 'mixins'

module GoodData
  module Mixin
    module RestResource
      def self.included(base)
        # Core REST Object Stuff
        base.extend GoodData::Mixin::RootKeySetter
        base.send :include, GoodData::Mixin::RootKeyGetter
        base.send :include, GoodData::Mixin::DataGetter
        base.send :include, GoodData::Mixin::MetaGetter
        base.send :include, GoodData::Mixin::ObjId
        base.send :include, GoodData::Mixin::ContentGetter
        base.send :include, GoodData::Mixin::Timestamps
        base.send :include, GoodData::Mixin::Links

        base.extend GoodData::Mixin::DataPropertyReader
        base.extend GoodData::Mixin::DataPropertyWriter
        base.extend GoodData::Mixin::MetaPropertyReader
        base.extend GoodData::Mixin::MetaPropertyWriter

        # MdObject Stuff
        base.send :include, GoodData::Mixin::MdJson
        base.send :include, GoodData::Mixin::NotAttribute
        base.send :include, GoodData::Mixin::NotExportable
        base.send :include, GoodData::Mixin::NotFact
        base.send :include, GoodData::Mixin::NotMetric
        base.send :include, GoodData::Mixin::NotLabel
        base.send :include, GoodData::Mixin::MdRelations
        base.send :include, GoodData::Mixin::Author

        base.extend GoodData::Mixin::MdObjId
        base.extend GoodData::Mixin::MdObjectQuery
        base.extend GoodData::Mixin::MdObjectIndexer
        base.extend GoodData::Mixin::MdFinders
        base.extend GoodData::Mixin::MdIdToUri
      end
    end
  end
end
