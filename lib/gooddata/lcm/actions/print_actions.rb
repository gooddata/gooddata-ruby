# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class PrintActions < BaseAction
      DESCRIPTION = 'Print Information About Actions'

      PARAMS = {
      }

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          results = []

          actions = GoodData::LCM2::BaseAction.descendants

          actions.each do |action|
            action_params = action.const_get(:PARAMS)
            action_params_keys = action_params.keys
            params = action_params_keys.map do |param|
              param
            end

            types = action_params.map do |k, param|
              param[:type].class.short_name
            end

            required = action_params.map do |k, param|
              param[:opts][:required]
            end

            defaults = action_params.map do |k, param|
              param[:opts][:default]
            end

            results << {
              name: action.short_name,
              description: action.const_get(:DESCRIPTION),
              params: params.join("\n"),
              types: types.join("\n"),
              required: required.join("\n"),
              default: defaults.join("\n")
            }
          end

          # Return results
          results
        end
      end
    end
  end
end
