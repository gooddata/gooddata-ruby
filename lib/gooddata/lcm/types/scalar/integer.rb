# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../base_type'

module GoodData
  module LCM2
    module Type
      class IntegerType < BaseType
        CATEGORY = :scalar
        INTERNAL_TYPE = Integer

        def check(value)
          true
        end
      end
    end
  end
end
