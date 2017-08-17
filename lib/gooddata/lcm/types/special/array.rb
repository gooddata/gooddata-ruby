# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module LCM2
    module Type
      class ArrayType
        CATEGORY = :special

        def initialize(type)
          @type = type
        end

        def check(values)
          return false unless values.is_a?(Array)

          values.each do |value|
            return false unless @type.check(value)
          end

          true
        end

        def to_s
          "#{self.class.short_name}<#{@type}>"
        end
      end
    end
  end
end
