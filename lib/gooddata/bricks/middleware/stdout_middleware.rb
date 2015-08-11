# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_middleware'

module GoodData
  module Bricks
    class STDOUTLoggingMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash
        logger = Logger.new(STDOUT)
        params[:logger] = logger
        logger.info('Pipeline starting with STDOUT logger')
        returning(@app.call(params)) do
          logger.info('Pipeline ending')
        end
      end
    end
  end
end
