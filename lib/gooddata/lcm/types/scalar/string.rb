# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../base_type'

module GoodData
  module LCM2
    module Type
      class StringType < BaseType
        CATEGORY = :scalar
        INTERNAL_TYPE = String

        def check(value)
          value.is_a?(String)
        end

        def migrate(value, to_type)
          case to_type
          when GoodData::LCM2::Type::ArrayType
            value.nil? ? (true) : ([value])
          else
            value.nil? ? (false) : (fail "Can not migrate String to #{to_type}")
          end
        end
      end
    end
  end
end
