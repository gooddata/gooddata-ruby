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
        ABORT_ON_ERROR_PARAM = 'abort_on_error'.to_sym
        COLLECT_SYNCED_STATUS = 'collect_synced_status'.to_sym

        def check_params(specification, params)
          specification.keys.each do |param_name|
            value = params.send(param_name)
            type = specification[param_name][:type]
            if value.nil? || (value.is_a?(String) && value.empty?)
              if !specification[param_name][:opts][:default].nil?
                if specification.select { |x| specification[x][:opts][:replacement] == param_name }.first.nil?
                  params[param_name] = specification[param_name][:opts][:default]
                else
                  GoodData.logger.warn "WARNING: Default value for parameter '#{param_name}' was not filled because deprecated parameter is used instead."
                end
              elsif specification[param_name][:opts][:required]
                fail_if_development "Mandatory parameter '#{param_name}' of type '#{type}' is not specified"
              end
            else
              if type.class.const_get(:CATEGORY) == :complex && !value.is_a?(Hash)
                fail_if_development "Expected parameter '#{param_name}' to be kind of '#{type}', got '#{value.class.name}'"
              end

              if specification[param_name][:opts][:deprecated]
                GoodData.logger.warn("WARNING: Parameter '#{param_name}' is deprecated. Please use '#{specification[param_name][:opts][:replacement]}' instead.")
              end

              unless type.check(value)
                fail_if_development "Parameter '#{param_name}' has invalid type, expected: #{type}, got #{value.class}"
              end
            end
          end
        end

        def continue_on_error(params)
          params.include?(ABORT_ON_ERROR_PARAM) && !to_bool(ABORT_ON_ERROR_PARAM, params[ABORT_ON_ERROR_PARAM])
        end

        def collect_synced_status(params)
          params.include?(COLLECT_SYNCED_STATUS) && to_bool(COLLECT_SYNCED_STATUS, params[COLLECT_SYNCED_STATUS])
        end

        private

        def to_bool(key, value)
          return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)
          return true if value =~ /^(true|t|yes|y|1)$/i
          return false if value == '' || value =~ /^(false|f|no|n|0)$/i

          raise ArgumentError, "Invalid '#{value}' boolean value for '#{key}' parameter"
        end
      end
    end
  end
end
