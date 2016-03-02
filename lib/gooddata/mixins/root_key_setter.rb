# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Mixin
    module RootKeySetter
      def root_key(a_key)
        define_method :root_key, proc { a_key.to_s }
      end
    end
  end
end
