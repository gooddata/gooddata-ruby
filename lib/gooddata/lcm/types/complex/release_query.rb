# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../base_type'

require_relative '../special/array'
require_relative 'complex'

module GoodData
  module LCM2
    module Type
      class ReleaseQueryType < ComplexType
        CATEGORY = :complex

        PARAMS = define_type(self) do
          description 'Select Query'
          param :select, instance_of(Type::StringType), required: false

          description 'Insert Query'
          param :insert, instance_of(Type::StringType), required: false

          description 'Update Query'
          param :update, instance_of(Type::StringType), required: false
        end

        def check(value)
          BaseType.check_params(PARAMS, value)
        end
      end
    end
  end
end
