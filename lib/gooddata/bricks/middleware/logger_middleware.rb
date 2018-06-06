# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
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
          logger = params[:GDC_LOGGER_FILE].nil? ? Logger.new(STDOUT) : Logger.new(params[:GDC_LOGGER_FILE])
          logger.level = params['GDC_LOG_LEVEL'] if params['GDC_LOG_LEVEL']
          logger.info('Pipeline starts')

          original_formatter = Logger::Formatter.new
          logger.formatter = proc { |severity, datetime, progname, msg, to_splunk=params['SPLUNK_LOG_ALL']|
            GoodData.splunk_logger.formatter.call(severity, datetime, progname, msg.dump) if to_splunk.to_s == "true"
            original_formatter.call(severity, datetime, progname, msg.dump)
          }
        end
        params['GDC_LOGGER'] = logger

        GoodData.logging_splunk_on
        GoodData.logging_http_on if params['HTTP_LOGGING'] && params['HTTP_LOGGING'].to_b

        returning(@app.call(params)) do |_result|
          logger.info('Pipeline ending')
        end
      end
    end
  end
end
