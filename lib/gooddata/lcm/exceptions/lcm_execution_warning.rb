# frozen_string_literal: true
# (C) 2019-2022 GoodData Corporation

module GoodData
  class LcmExecutionWarning < RuntimeError
    DEFAULT_MSG = 'Existing errors during lcm execution'

    attr_reader :summary_error

    def initialize(summary_error, message = DEFAULT_MSG)
      super(message)
      @summary_error = summary_error
    end
  end
end
