# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Mixin
    module PropertyAccessor
      def property_reader(where, *props)
        props.each do |prop|
          define_method prop, proc {
            self.instance_variable_get(where)[prop]
          }
        end
      end

      def property_writer(where, *props)
        props.each do |prop|
          define_method "#{prop}=", proc { |val| self.instance_variable_get(where)[prop] = val }
        end
      end

      def property_accessor(*args)
        property_reader(*args)
        property_writer(*args)
      end
    end
  end
end
