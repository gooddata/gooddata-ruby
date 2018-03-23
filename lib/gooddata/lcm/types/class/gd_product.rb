# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../base_type'

require_relative 'class'

module GoodData
  module LCM2
    module Type
      class GDDataProductType < ClassType
        CATEGORY = :class

        def check(value)
          value.class == GoodData::DataProduct
        end
      end
    end
  end
end
