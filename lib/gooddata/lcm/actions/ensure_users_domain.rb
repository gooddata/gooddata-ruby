# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class EnsureUsersDomain < BaseAction
      DESCRIPTION = 'Ensure Domain Users - Based On Input Source Data'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gd_client, instance_of(Type::GdClientType), required: true
      end

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          results = []

          # Return results
          results
        end
      end
    end
  end
end
