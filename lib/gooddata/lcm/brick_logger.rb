# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  # Simple file logger.
  class BrickFileLogger
    # entry-point
    # @param [String] log_directory directory to create log files
    # @param [String] log_file - file to log
    def initialize(log_directory, log_file)
      @log_directory = log_directory
      @log_file = log_file
    end

    # Creates file in log directory with given content. Logging is disabled when log_directory is nil.
    #
    # @param [String] content log file content
    def log_action(content)
      FileUtils.mkpath @log_directory
      File.open("#{@log_directory}/#{@log_file}", 'a') { |file| file.write(content + "\n") }
    end
  end
end
