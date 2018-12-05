# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'logger'

require 'gooddata/extensions/true'
require 'gooddata/extensions/false'
require 'gooddata/extensions/integer'
require 'gooddata/extensions/string'
require 'gooddata/extensions/nil'

using TrueExtensions
using FalseExtensions
using IntegerExtensions
using StringExtensions
using NilExtensions

require_relative 'base_middleware'
require_relative 'mask_logger_decorator'

module GoodData
  module Bricks
    class LoggerMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash
        if params['GDC_LOGGING_OFF']
          logger = NilLogger.new
        elsif params['GDC_LOG_DIRECTORY'] && params['GDC_EXECUTION_ID']
          log_directory = params['GDC_LOG_DIRECTORY']
          execution_id = params['GDC_EXECUTION_ID']
          FileUtils.mkpath log_directory
          logger = Logger.new("#{log_directory}/#{execution_id}.log")
          logger.level = params['GDC_LOG_LEVEL'] || 'info'
          values_to_mask = params['values_to_mask'] || []
          logger = MaskLoggerDecorator.new(logger, values_to_mask) if values_to_mask.any?
        else
          logger = params[:GDC_LOGGER_FILE].nil? ? Logger.new(STDOUT) : Logger.new(params[:GDC_LOGGER_FILE])
          logger.level = params['GDC_LOG_LEVEL'] || 'info'
        end
        GoodData.logger = logger
        logger.info('Pipeline starts')
        params['GDC_LOGGER'] = logger
        GoodData.logging_http_on if params['HTTP_LOGGING'] && params['HTTP_LOGGING'].to_b

        returning(@app.call(params)) do |_result|
          logger.info('Pipeline ending')
        end
      end
    end
  end
end
