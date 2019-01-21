# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'logger'
require 'gooddata/core/splunk_logger'

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
require_relative 'context_logger_decorator'

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

        # Initialize splunk logger
        if params['SPLUNK_LOGGING'] && params['SPLUNK_LOGGING'].to_b
          GoodData.logger.info "Statistics collecting is turned ON. All the data is anonymous."
          splunk_logger = SplunkLogger.new params['SPLUNK_LOG_PATH'] || GoodData::DEFAULT_SPLUNKLOG_OUTPUT
          splunk_logger.level = params['SPLUNK_LOG_LEVEL'] || GoodData::DEFAULT_SPLUNKLOG_LEVEL
          splunk_logger = splunk_logger.extend(ContextLoggerDecorator)
          splunk_logger.context_source = GoodData.gd_logger
          values_to_mask = params['values_to_mask'] || []
          values_to_mask.concat MaskLoggerDecorator.extract_values params
          splunk_logger = MaskLoggerDecorator.new(splunk_logger, values_to_mask) if values_to_mask.any?
        else
          splunk_logger = NilLogger.new
        end
        GoodData.splunk_logging_on splunk_logger

        # Initialize context: Execution ID
        GoodData.gd_logger.execution_id = params['GDC_EXECUTION_ID'] || SecureRandom.urlsafe_base64(16)

        returning(@app.call(params)) do |_result|
          logger.info('Pipeline ending')
        end
      end
    end
  end
end
