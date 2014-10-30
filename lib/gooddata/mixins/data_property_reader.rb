# encoding: UTF-8

require_relative 'data_getter'

module GoodData
  module Mixin
    module DataPropertyReader
      def data_property_reader(*props)
        props.each do |prop|
          define_method prop, proc { data[prop.to_s] }
        end
      end
    end
  end
end
