# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'logger'

require 'multi_json'

require_relative 'base_middleware'

module GoodData
  module Bricks
    class ParamsInspectMiddleware < Bricks::Middleware
      def call(params)
        inspect = params[:inspect_params] || params['inspect_params']
        puts 'Inspecting Parameters ...'
        puts MultiJson.dump(params, :pretty => true) if inspect.to_b
      end
    end
  end
end
