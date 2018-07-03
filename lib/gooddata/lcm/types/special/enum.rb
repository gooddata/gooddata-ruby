# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module LCM2
    module Type
      class EnumType
        CATEGORY = :special

        def check(value)
          values.include?(value) ||
            fail("Invalid parameter value '#{value}'. " \
                 "Possible values: #{values}")
        end
      end
    end
  end
end
