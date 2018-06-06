# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  # Dummy implementation of logger
  class SplunkLogger < Logger

    def initialize(input = STDERR)
      super(input)
      @formatter = Logger::Formatter.new

      @logs = ""
    end

    def clear_logs
      @logs = ""
    end

    def log(log, time, buffered=true)
      if buffered == true
        logs << @formatter.call("WARN", time, nil, log).to_s << "\n"
      else
        warn(log)
      end
    end

    def flush
      # GoodData::Helpers::SplunkHelper::send_logs GoodData.logger.splunk_logs
      STDERR.puts logs if logs.length > 0
      clear_logs
    end

  end
end
