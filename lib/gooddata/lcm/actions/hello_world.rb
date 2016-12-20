# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class HelloWorld < BaseAction
      DESCRIPTION = 'Print Hello World Message'

      PARAMS = define_params(self) do
        description 'Message to be printed'
        param :message, instance_of(Type::StringType), required: true

        description 'Number of Iterations'
        param :iterations, instance_of(Type::IntegerType), required: false, default: 1
      end

      class << self
        def say(msg)
          puts "#{self.name}#say - #{msg}"
        end

        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          say(params.message)

          msg = {
            message: params.message
          }
          results = [msg]

          # Return results
          results
        end
      end
    end
  end
end
