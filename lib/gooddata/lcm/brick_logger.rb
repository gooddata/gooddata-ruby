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
    # @param [String] mode - brick mode (short name if brick)
    def initialize(log_directory, mode)
      @log_directory = log_directory
      @mode = mode
    end

    # Creates file in log directory with given content. Logging is disabled when log_directory is nil.
    #
    # @param [String] status brick phase/status (start, finished, error,...)
    # @param [String] content log file content
    def log_action(status, content)
      File.write("#{@log_directory}/#{@mode}_#{status}.json", content)
    end
  end
end
