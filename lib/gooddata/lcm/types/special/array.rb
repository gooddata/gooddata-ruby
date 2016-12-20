# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../base_type'

module GoodData
  module LCM2
    module Type
      class ArrayType < BaseType
        CATEGORY = :special

        def initialize(type)
          @type = type
        end

        def check(values)
          return false unless values.kind_of?(Array)

          values.each do |value|
            return false unless @type.check(value)
          end

          true
        end

        def to_s
          "#{self.class.name.split('::').last}<#{@type.to_s}>"
        end
      end
    end
  end
end
