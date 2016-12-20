# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class PrintModes < BaseAction
      DESCRIPTION = 'Print Modes'

      PARAMS = {
      }

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          results = []
          GoodData::LCM2::MODES.keys.each_with_index do |mode, index|
            actions = GoodData::LCM2::MODES[mode]
            action_names = actions.map do |k, action|
              params_length = k.const_get(:PARAMS).keys.length
              k.short_name + ("\n" * (params_length > 1 ? params_length - 1 : 0))
            end

            params = actions.map do |action|
              action.const_get(:PARAMS).map do |k, param|
                res = param[:name]
              end
            end

            types = actions.map do |action|
              action.const_get(:PARAMS).map do |k, param|
                param[:type]
                # param[:type].class.short_name
              end
            end

            required = actions.map do |action|
              action.const_get(:PARAMS).map do |k, param|
                param[:opts][:required]
              end
            end

            defaults = actions.map do |action|
              action.const_get(:PARAMS).map do |k, param|
                param[:opts][:default]
              end
            end

            results << {
              '#': index,
              mode: mode,
              actions: action_names.join("\n"),
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
