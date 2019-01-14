# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../../mixins/property_accessor'
require_relative '../../lcm/helpers/helpers'

module GoodData
  module ContextManager
    extend GoodData::Mixin::PropertyAccessor

    property_accessor :@context, :action
    property_accessor :@context, :brick
    property_accessor :@context, :execution_id
    property_accessor :@context, :status

    def initialize_context
      @action_start = Time.now

      # :log_v is used to differentiate new versions of logs in splunk
      @context = {
        :api_version => GoodData.version,
        :log_v => 0,
        :component => 'lcm.ruby',
        :status => :not_in_action
      }
    end

    # Return current brick context extended with time specific information
    #
    # @param [Time] now, allows to specify exact time, when outer call was performed
    # @return [Hash] Brick context
    def context(now = Time.now)
      time_specific_context = action ? { :time => time_from_action_start(now) } : {}
      @context.merge(time_specific_context)
    end

    def time_from_action_start(now = Time.now)
      fail_if_development 'No action is being profiled' unless action
      (now - @action_start) * 1000
    end

    # Starts lcm action
    #
    # @param [String] action, name of the action
    # @param [Logger] logger, logger that should log current context info
    # @param [Time] now, allows to specify exact time, when outer call was performed
    def start_action(next_action, logger = nil, now = Time.now)
      fail_if_development 'An action is already being profiled' if action

      self.action = next_action
      @action_start = now
      logger.info '' if logger
      self.status = :action_in_progress
    end

    # Ends currently opened lcm action
    #
    # @param [Logger] logger, logger that should log current context info
    def end_action(logger = nil)
      fail_if_development 'No matching action to start found' unless action

      logger.info '' if logger
      self.status = :not_in_action
      self.action = nil
    end
  end
end
