# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  # ContextManager module implements methods for brick context storage
  module ContextManager
    # STATUS_OUTSIDE ~ when there is no active action
    # STATUS_IN_PROGRESS ~ execution is inside of some action
    # STATUS_START ~ immediately after action start
    # STATUS_START ~ immediately after action end
    STATUS_OUTSIDE = :outside
    STATUS_IN_PROGRESS = :in_progress
    STATUS_START = :start
    STATUS_END = :end
    UNDEFINED = :undefined

    def initialize_context
      @action_start = Time.now

      # context[:log_v] is used to differentiate new versions of logs in splunk
      @context = {
        :api_version => GoodData.version,
        :log_v => 0,
        :component => 'lcm.ruby',
        :action => UNDEFINED,
        :brick => UNDEFINED,
        :status => STATUS_OUTSIDE,
        :execution_id => UNDEFINED
      }
    end

    # Return current brick context extended with time specific information
    #
    # @param [Time] now, allows to specify exact time, when outer call was performed
    # @return [Hash] Brick context
    def context(now = Time.now)
      time_specific_context = action == UNDEFINED ? {} : { :time => time_from_action_start(now) }
      @context.merge(time_specific_context)
    end

    def action=(action)
      @context[:action] = action
    end

    def action
      @context[:action]
    end

    def brick=(brick)
      @context[:brick] = brick
    end

    def brick
      @context[:brick]
    end

    def execution_id=(execution_id)
      @context[:execution_id] = execution_id
    end

    def execution_id
      @context[:execution_id]
    end

    def status=(status)
      @context[:status] = status
    end

    def status
      @context[:status]
    end

    def time_from_action_start(now = Time.now)
      0 if action == UNDEFINED
      (now - @action_start) * 1000
    end

    # Starts lcm action
    #
    # @param [String] action, name of the action
    # @param [Logger] logger, logger that should log current context info
    # @param [Time] now, allows to specify exact time, when outer call was performed
    def start_action(action, logger = nil, now = Time.now)
      end_action
      self.action = action
      @action_start = now
      self.status = STATUS_START
      logger.info '' if logger
      self.status = STATUS_IN_PROGRESS
    end

    # Ends currently opened lcm action
    #
    # @param [Logger] logger, logger that should log current context info
    def end_action(logger = nil)
      return if action == UNDEFINED || @context[:status] == STATUS_OUTSIDE

      self.status = STATUS_END
      logger.info '' if logger
      self.status = STATUS_OUTSIDE
      self.action = UNDEFINED
    end
  end
end
