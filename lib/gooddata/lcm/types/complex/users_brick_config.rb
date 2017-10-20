# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../base_type'

require_relative '../special/array'
require_relative 'complex'

module GoodData
  module LCM2
    module Type
      class UsersBrickConfig < ComplexType
        CATEGORY = :complex

        PARAMS = define_type(self) do
          description 'Source of the users table'
          param :input_source, instance_of(Type::HashType), required: true

          description 'Name of the column of user logins'
          param :login_column, instance_of(Type::StringType), required: false
        end

        def check(value)
          BaseType.check_params(PARAMS, value)
        end
      end
    end
  end
end
