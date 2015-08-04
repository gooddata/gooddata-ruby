# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'highline'

# Define GoodData::CLI as GLI Wrapper
module GoodData
  module CLI
    DEFAULT_TERMINAL = HighLine.new unless const_defined?(:DEFAULT_TERMINAL)

    class << self
      def terminal
        DEFAULT_TERMINAL
      end
    end
  end
end
