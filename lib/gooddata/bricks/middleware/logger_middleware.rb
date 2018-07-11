# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

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
          logger = params[:GDC_LOGGER_FILE].nil? ? GoodData::GDLogger.new(STDOUT) : GoodData::GDLogger.new(params[:GDC_LOGGER_FILE])
          logger.level = params['GDC_LOG_LEVEL'] if params['GDC_LOG_LEVEL']
          logger.info('Pipeline starts')

          logger.log_to_splunk = true if params['COLLECT_STATS'] && params['COLLECT_STATS'].to_b && params['SPLUNK_LOG_ALL'] && params['SPLUNK_LOG_ALL'].to_b
        end
        params['GDC_LOGGER'] = logger

        if params['COLLECT_STATS'] && params['COLLECT_STATS'].to_b
          GoodData.logger.warn "Statistics collecting is turned ON. We are collecting some data for execution performance analysis - all sensitive information are being anonymized."
          GoodData.logging_splunk_on Logger::INFO, STDERR, GoodData::SplunkLogger, :file_output => true
        end

        GoodData.logging_http_on if params['HTTP_LOGGING'] && params['HTTP_LOGGING'].to_b

        returning(@app.call(params)) do |_result|
          logger.info('Pipeline ending')
        end
      end
    end
  end
end
