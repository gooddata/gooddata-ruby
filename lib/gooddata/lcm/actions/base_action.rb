# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
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
      end
    end
  end
end
