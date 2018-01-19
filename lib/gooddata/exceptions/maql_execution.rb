# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class MaqlExecutionError < RuntimeError
    attr_accessor :data

    def initialize(message, data = nil)
      super(message || 'Execution of maql failed')
      @data = data
    end
  end
end
