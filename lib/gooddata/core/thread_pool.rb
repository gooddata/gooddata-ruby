# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'concurrent'

module GoodData
  class << self
    DEFAULT_THREAD_COUNT = 100

    def thread_pool
      @pool ||= Concurrent::FixedThreadPool.new thread_count
    end

    def thread_count
      @thread_count || DEFAULT_THREAD_COUNT
    end

    def thread_count=(number)
      if number && number.to_i > 0
        @thread_count = number.to_i
        @pool = Concurrent::FixedThreadPool.new thread_count
      end
    end
  end
end
