# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  # Dummy implementation of logger
  class SplunkLogger < Logger
    BUFFERED = 1 << 0
    API_MODE = 1 << 1
    FILE_MODE = 1 << 2

    BRICK_CONTEXT = :brick
    ACTION_CONTEXT = :action

    class << self
      def hash_to_string(hash)
        str = ""
        hash.each do |pair|
          str += " "
          str += pair[0].to_s + "="
          str += pair[1].to_s
        end
        str
      end
    end

    def initialize(output = STDERR, mode = BUFFERED | FILE_MODE)
      super(output)
      @formatter = Logger::Formatter.new
      @logs = ""
      @mode = mode
      @context = {
        :api_version => GoodData.version,
        :log_v => 0,
        :action => "undefined",
        :brick => "undefined"
      }
    end

    def set_context(key, val)
      @context[key] = val
    end

    def clear_logs
      @logs = ""
    end

    def extract_mode(mode)
      return mode == (mode & @mode)
    end

    def add(severity, message = nil, progname = nil)
      context = SplunkLogger.hash_to_string(@context)
      if message.class == Hash
        message = SplunkLogger.hash_to_string(message) + context
      elsif message.nil?
        message = context
      else
        message = message.to_s + context
      end

      now = Time.now
      severity = format_severity severity
      if extract_mode BUFFERED
        @logs << @formatter.call(severity, now, nil, message).to_s << "\n"
      else
        GoodData::Helpers::SplunkHelper.send_logs @formatter.call(severity, now, progname, message).to_s if extract_mode API_MODE
        super(severity, message, progname) if extract_mode FILE_MODE
      end
    end

    def flush
      unless @logs.empty?
        GoodData::Helpers::SplunkHelper.send_logs @logs if extract_mode API_MODE
        STDERR.puts @logs if extract_mode FILE_MODE
        clear_logs
      end
    end
  end
end
