# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the

# LICENSE file in the root directory of this source tree.

require_relative '../types/param'

module GoodData
  module LCM2
    module Dsl
      class TypeDsl
        def initialize
          @params = {}

          self.new_param
        end

        attr_reader :params

        def array_of(type)
          Type::ArrayType.new(type)
        end

        def instance_of(type)
          type.new
        end

        def one_of(type)
          Type::EnumType.new
        end

        def new_param
          @param = Type::Param.new()
        end

        def description(desc)
          @param.description = desc
        end

        def param(name, type, opts = {})
          @param.name = name
          @param.type = type
          @param.opts = opts

          @params[name] = {
            name: @param.name,
            type: @param.type,
            opts: @param.opts,
            description: @param.description,
            category: @param.type.class.const_get(:CATEGORY)
          }

          # Create new instance of param
          self.new_param
        end
      end
    end
  end
end
