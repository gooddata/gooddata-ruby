# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../dsl/dsl'
require_relative '../helpers/helpers'
require_relative '../types/types'

module GoodData
  module LCM2
    class BaseAction
      class << self
        include Dsl::Dsl

        def check_params(specification, params)
          Helpers.check_params(specification, params)
        end

        # This method is used to enable the possibility to read keys of params object
        # which are not specified in the specification constant
        # typically in case when method access params dynamically based on user input
        def without_check(specification, params)
          params.clear_filters # disables params validation
          result = yield
          params.setup_filters(specification) # enables params validation
          result
        end
      end
    end
  end
end
