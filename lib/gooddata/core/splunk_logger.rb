# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  # Dummy implementation of logger
  class SplunkLogger < Logger
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

    attr_accessor :logs

    def initialize(output = STDERR, modes = nil)
      super(output)
      @logs = ""
      @modes = { :buffering => false, :api_output => false, :file_output => false }
      unless modes.nil?
        [:buffering, :api_output, :file_output].each do |mode|
          @modes[mode] = modes[mode] if modes.key?(mode)
        end
      end

      @context = {
        :api_version => GoodData.version,
        :log_v => 0,
        :action => "undefined",
        :brick => "undefined"
      }

      @params_filter = nil

      @formatter = proc { |severity, datetime, progname, msg|
        filter_string! msg unless msg.nil?
        filter_string! progname unless progname.nil?
        @default_formatter.call severity, datetime, progname, msg
      }
    end

    def filter_string!(str)
      str.gsub! @params_filter, "****" unless @params_filter.nil?
    end

    def params_filter(map)
      @params_filter = filter_from_param_array map.values
      @params_filter = Regexp.new @params_filter.join("|")
    end

    def filter_from_param_array(arr)
      filter = []
      arr.each do |val|
        filter << "(" + Regexp.quote(val) + ")" if val.class == String
        filter.concat filter_from_param_array(val) if val.class == Array
        filter.concat filter_from_param_array(val.values) if val.class == Hash
      end
      filter
    end

    def mode_on(mode)
      @modes[mode] = true
    end

    def mode_off(mode)
      @modes[mode] = false
    end

    [:buffering, :api_output, :file_output].each do |mode|
      define_method :"#{mode}_on" do
        mode_on(mode)
      end

      define_method :"#{mode}_off" do
        mode_off(mode)
      end

      define_method :"#{mode}_on?" do
        @modes[mode]
      end
    end

    def set_context(key, val)
      @context[key] = val
    end

    def clear_logs
      @logs = ""
    end

    def add(severity, message = nil, progname = nil, time = nil)
      severity ||= UNKNOWN
      return true if severity < @level

      if message.nil?
        message = progname
        progname = nil
      end

      context = SplunkLogger.hash_to_string(@context)
      if message.class == Hash
        message_formatted = SplunkLogger.hash_to_string(message) + context
      elsif message.nil?
        message_formatted = context
      else
        message_formatted = message.to_s + context
      end

      now = (time.nil? ? Time.now : time)
      severity_formatted = format_severity severity

      if buffering_on?
        @logs << @formatter.call(severity_formatted, now, progname, message_formatted).to_s
      else
        GoodData::Helpers::SplunkHelper.send_logs @formatter.call(severity_formatted, now, progname, message_formatted).to_s if api_output_on?
        super(severity, message_formatted, progname) if file_output_on?
      end
    end

    def flush
      unless @logs.empty?
        GoodData::Helpers::SplunkHelper.send_logs @logs if api_output_on?
        @logdev.write @logs if file_output_on? && !@logdev.nil?
        clear_logs
      end
    end
  end
end
