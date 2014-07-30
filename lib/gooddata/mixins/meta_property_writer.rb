# encoding: UTF-8

module GoodData
  module Mixin
    module MetaPropertyWriter
      def metadata_property_writer(*props)
        props.each do |prop|
          define_method "#{prop}=", proc { |val| meta[prop.to_s] = val }
        end
      end
    end
  end
end
