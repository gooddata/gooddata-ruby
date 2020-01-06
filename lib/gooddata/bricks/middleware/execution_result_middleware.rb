# Copyright (c) 2019, GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_middleware'

# rubocop:disable Style/ClassVars
module GoodData
  module Bricks
    module ExecutionStatus
      OK = 'OK'
      ERROR = 'ERROR'
      WARNING = 'WARNING'
    end

    class ExecutionResultMiddleware < Bricks::Middleware
      @@result_log_path = nil

      def call(params)
        result_log_path(params)
        @app.call(params)
      end

      # Update process execution result when the script is executed inside a GDC ETL process execution (ruby bricks).
      # Ruby bricks should update execution result at the end of script with status=WARNING or OK and summary message if the script exits normally.
      # If any fatal error, script should update execution result with status=ERROR and error message,
      # then throw exception to notify GDC platform that the script terminated unexpectedly.
      # @param [HashMap] params contains GDC_EXECUTION_RESULT_LOG_PATH or GDC_LOG_DIRECTORY, GDC_EXECUTION_ID
      # @param [ExecutionStatus] status execution status
      # @param [String] message execution message
      def self.update_execution_result(status, message = "")
        if status != ExecutionStatus::OK && status != ExecutionStatus::ERROR && status != ExecutionStatus::WARNING
          GoodData.logger.warn("Unknown execution status #{status}, ignored it.")
        end

        result = {
          executionResult: {
            status: status,
            message: message
          }
        }
        update_result(result)
      end

      private

      def result_log_path(params)
        log_directory = params['GDC_LOG_DIRECTORY']
        execution_id = params['GDC_EXECUTION_ID']
        result_log_path = params['GDC_EXECUTION_RESULT_LOG_PATH'] || ENV['GDC_EXECUTION_RESULT_LOG_PATH']
        result_log_path = "#{log_directory}/#{execution_id}_result.json" if result_log_path.nil? && !log_directory.nil?
        @@result_log_path = result_log_path
      end

      def self.update_result(result)
        if @@result_log_path.nil?
          GoodData.gd_logger.warn("action=update_execution_result status=error Not found execution result logger file.") unless GoodData.gd_logger.nil?
          return
        end

        File.open(@@result_log_path, 'w') { |file| file.write(JSON.pretty_generate(result)) }
      rescue Exception => e # rubocop:disable RescueException
        GoodData.gd_logger.error("action=update_execution_result status=error reason=#{e.message}") unless GoodData.gd_logger.nil?
      end
    end
  end
end
# rubocop:enable Style/ClassVars
