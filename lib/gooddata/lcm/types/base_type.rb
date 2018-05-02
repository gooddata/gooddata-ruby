# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the

# LICENSE file in the root directory of this source tree.

require_relative '../dsl/dsl'
require_relative '../helpers/helpers'

module GoodData
  module LCM2
    module Type
      class BaseType
        class << self
          include Dsl::Dsl

          def check_params(specification, params)
            Helpers.check_params(specification, params)
          end
        end

        def migrate?(to_type)
          migrate(nil, to_type)
        end

        def migrate(value, to_type)
          value.nil? ? (false) : (fail "Can not migrate #{self.class} to #{to_type}")
        end

        def to_s
          self.class.short_name
        end
      end
    end
  end
end
