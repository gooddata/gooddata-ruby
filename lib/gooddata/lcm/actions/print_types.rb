# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class PrintTypes < BaseAction
      DESCRIPTION = 'Print Information About Defined Types'

      PARAMS = {
      }

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          results = []

          GoodData::LCM2::Dsl::Dsl::TYPES.each_pair do |k, v|
            vals = []
            v.each_pair do |name, val|
              vals << val[:type]
            end

            required = []
            v.each_pair do |name, val|
              required << val[:opts][:required]
            end

            defaults = []
            v.each_pair do |name, val|
              defaults << val[:opts][:default]
            end

            results << {
              class: k.short_name,
              param: v.keys.join("\n"),
              type: vals.join("\n"),
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
