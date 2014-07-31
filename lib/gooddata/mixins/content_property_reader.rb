# encoding: UTF-8

module GoodData
  module Mixin
    module ContentPropertyReader
      def content_property_reader(*props)
        props.each do |prop|
          define_method prop, proc { content[prop.to_s] }
        end
      end
    end
  end
end
