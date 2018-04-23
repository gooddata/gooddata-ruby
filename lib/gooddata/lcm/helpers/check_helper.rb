# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'json'

module GoodData
  module LCM2
    class Helpers
      class << self
        def check_params(specification, params)
          specification.keys.each do |param_name|
            value = params.send(param_name)
            type = specification[param_name][:type]
            if value.nil? || (value.is_a?(String) && value.empty?)
              if specification[param_name][:opts][:default]
                params[param_name] = specification[param_name][:opts][:default]
              elsif specification[param_name][:opts][:required]
                fail("Mandatory parameter '#{param_name}' of type '#{type}' is not specified")
              end
            else
              if type.class.const_get(:CATEGORY) == :complex && !value.is_a?(Hash)
                puts JSON.pretty_generate(params)
                fail "Expected parameter '#{param_name}' to be kind of '#{type}', got '#{value.class.name}'"
              end

              if specification[param_name][:opts][:deprecated]
                if specification[specification[param_name][:opts][:replacement]][:type].class == type.class
                  params[specification[param_name][:opts][:replacement]] = value
                elsif type.migrate?(specification[specification[param_name][:opts][:replacement]][:type])
                  params[specification[param_name][:opts][:replacement]] = type.migrate(value, specification[specification[param_name][:opts][:replacement]][:type])
                end
                puts "WARNING: Parameter '#{param_name}' is deprecated. Please use '#{specification[param_name][:opts][:replacement]}' instead."
              end

              unless type.check(value)
                fail "Parameter '#{param_name}' has invalid type, expected: #{type}, got #{value.class}"
              end
            end
          end
        end
      end
    end
  end
end
