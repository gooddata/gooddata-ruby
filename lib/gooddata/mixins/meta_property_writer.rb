# encoding: UTF-8

require_relative 'meta_getter'

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
