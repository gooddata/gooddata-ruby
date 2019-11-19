# Copyright (c) 2010-2019 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class LcmExecutionError < RuntimeError
    DEFAULT_MSG = 'Error during lcm execution'

    attr_reader :summary_error

    def initialize(summary_error, message = DEFAULT_MSG)
      super(message)
      @summary_error = summary_error
    end
  end
end
