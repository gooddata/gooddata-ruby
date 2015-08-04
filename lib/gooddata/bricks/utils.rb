# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Bricks
    module Utils
      def returning(value, &block)
        fail 'Block was not provided' if block.nil?
        return_val = value
        block.call(value)
        return_val
      end
    end
  end
end
