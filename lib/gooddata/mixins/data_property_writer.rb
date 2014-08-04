# encoding: UTF-8

require_relative 'data_getter'

module GoodData
  module Mixin
    module DataPropertyWriter
      def data_property_writer(*props)
        props.each do |prop|
          define_method "#{prop}=", proc { |val| data[prop.to_s] = val }
        end
      end
    end
  end
end
