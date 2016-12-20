# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'json'

require_relative 'params_dsl'
require_relative 'type_dsl'

require_relative '../../helpers/global_helpers'

module GoodData
  module LCM2
    module Dsl
      module Dsl
        DEFAULT_OPTS = {
          required: false,
          default: nil
        }

        PARAMS = {}
        TYPES = {}

        def process(klass, type, caption, &block)
          dsl = type.new
          dsl.instance_eval(&block)

          # puts "#{caption}: #{klass.name}"
          # puts JSON.pretty_generate(dsl.params)
          # puts

          # yield if block_given?

          # Return params
          dsl.params
        end

        def define_params(klass, &block)
          PARAMS[klass] = self.process(klass, GoodData::LCM2::Dsl::ParamsDsl, 'PARAMS', &block)
        end

        def define_type(klass, &block)
          TYPES[klass] = self.process(klass, GoodData::LCM2::Dsl::TypeDsl, 'TYPE', &block)
        end
      end
    end
  end
end
