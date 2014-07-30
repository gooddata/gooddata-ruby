# encoding: UTF-8

module GoodData
  module Mixin
    module MetaPropertyReaderMixin
      def metadata_property_reader(*props)
        props.each do |prop|
          define_method prop, proc { meta[prop.to_s] }
        end
      end
    end
  end
end
