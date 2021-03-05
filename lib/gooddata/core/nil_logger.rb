# frozen_string_literal: true
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  # Dummy implementation of logger
  class NilLogger
    attr_accessor :level

    def initialize(*_args)
      @level = nil
    end

    # No body define need for dummy logger
    def debug(*_args)
    end

    alias_method :info, :debug
    alias_method :warn, :debug
    alias_method :error, :debug
    alias_method :add, :debug

    def debug?
      false
    end

    alias_method :info?, :debug?
    alias_method :warn?, :debug?
    alias_method :error?, :debug?
    alias_method :fatal?, :debug?
  end
end
