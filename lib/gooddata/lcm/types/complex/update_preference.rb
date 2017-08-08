# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../base_type'

require_relative '../scalar/bool'
require_relative 'complex'

module GoodData
  module LCM2
    module Type
      class UpdatePreferenceType < ComplexType
        CATEGORY = :complex

        PARAMS = define_type(self) do
          description 'Cascade Drop'
          param :cascade_drops, instance_of(Type::BooleanType), required: false, default: nil, deprecated: true, replacement: :allow_cascade_drops

          description 'Preserve Data'
          param :preserve_data, instance_of(Type::BooleanType), required: false, default: nil, deprecated: true, replacement: :keep_data

          description 'Allow Cascade Drop'
          param :allow_cascade_drops, instance_of(Type::BooleanType), required: false, default: false

          description 'Keep Data'
          param :keep_data, instance_of(Type::BooleanType), required: false, default: true
        end

        def check(value)
          BaseType.check_params(PARAMS, value)
        end
      end
    end
  end
end
