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
                if specification.select { |x| specification[x][:opts][:replacement] == param_name }.first.nil?
                  params[param_name] = specification[param_name][:opts][:default]
                else
                  GoodData.logger.warn "WARNING: Default value for parameter '#{param_name}' was not filled because deprecated parameter is used instead."
                end
              elsif specification[param_name][:opts][:required]
                fail("Mandatory parameter '#{param_name}' of type '#{type}' is not specified")
              end
            else
              if type.class.const_get(:CATEGORY) == :complex && !value.is_a?(Hash)
                fail "Expected parameter '#{param_name}' to be kind of '#{type}', got '#{value.class.name}'"
              end

              if specification[param_name][:opts][:deprecated]
                GoodData.logger.warn "WARNING: Parameter '#{param_name}' is deprecated. Please use '#{specification[param_name][:opts][:replacement]}' instead."
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
