# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'logger'

require_relative 'base_middleware'

module GoodData
  module Bricks
    class LoggerMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash
        logger = nil
        if params['GDC_LOGGING_OFF']
          logger = NilLogger.new
        else
          logger = params['GDC_LOGGER'] = params[:GDC_LOGGER_FILE].nil? ? Logger.new(STDOUT) : Logger.new(params[:GDC_LOGGER_FILE])
          logger.info('Pipeline starts')
        end
        returning(@app.call(params)) do |_result|
          logger.info('Pipeline ending')
        end
      end
    end
  end
end
