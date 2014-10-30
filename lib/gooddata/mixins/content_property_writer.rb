# encoding: UTF-8

module GoodData
  module Mixin
    module ContentPropertyWriter
      def content_property_writer(*props)
        props.each do |prop|
          define_method "#{prop}=", proc { |val| content[prop.to_s] = val }
        end
      end
    end
  end
end
