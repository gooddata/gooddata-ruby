# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'logger'
require 'gooddata/core/splunk_logger_decorator'

require 'gooddata/extensions/true'
require 'gooddata/extensions/false'
require 'gooddata/extensions/integer'
require 'gooddata/extensions/string'
require 'gooddata/extensions/nil'

require 'remote_syslog_logger'

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
          execution_log_path = params['GDC_EXECUTION_LOG_PATH'].nil? ? "#{log_directory}/#{execution_id}.log" : params['GDC_EXECUTION_LOG_PATH']
          logger = Logger.new(execution_log_path)
          logger.level = params['GDC_LOG_LEVEL'] || 'info'
          values_to_mask = params['values_to_mask'] || []
          logger = MaskLoggerDecorator.new(logger, values_to_mask)
        else
          logger = params[:GDC_LOGGER_FILE].nil? ? Logger.new(STDOUT) : Logger.new(params[:GDC_LOGGER_FILE])
          logger.level = params['GDC_LOG_LEVEL'] || 'info'
        end
        GoodData.logger = logger
        request_id = params.include?('GDC_REQUEST_ID') ? ", request_id=#{params['GDC_REQUEST_ID']}" : ''
        logger.info("Pipeline starts #{request_id}")
        params['GDC_LOGGER'] = logger
        GoodData.logging_http_on if params['HTTP_LOGGING'] && params['HTTP_LOGGING'].to_b

        unless params['NO_SPLUNK_LOGGING'] && params['NO_SPLUNK_LOGGING'].to_b
          GoodData.logger.info "Statistics collecting is turned ON. All the data is anonymous."
          # NODE_NAME is set up by k8s execmgr
          syslog_node = ENV['NODE_NAME']
          splunk_file_logger = syslog_node ? RemoteSyslogLogger.new(syslog_node, 514, program: "lcm_ruby_brick", facility: 'local2') : Logger.new(STDOUT)
          splunk_logger = SplunkLoggerDecorator.new splunk_file_logger
          splunk_logger.level = params['SPLUNK_LOG_LEVEL'] || GoodData::DEFAULT_SPLUNKLOG_LEVEL
          splunk_logger = splunk_logger.extend(ContextLoggerDecorator)
          splunk_logger.context_source = GoodData.gd_logger
          splunk_logger = MaskLoggerDecorator.new(splunk_logger, params)
          GoodData.splunk_logging_on splunk_logger
        end

        # Initialize context: Execution ID
        GoodData.gd_logger.execution_id = params['GDC_EXECUTION_ID'] || SecureRandom.urlsafe_base64(16)

        returning(@app.call(params)) do |_result|
          logger.info('Pipeline ending')
        end
      end
    end
  end
end
