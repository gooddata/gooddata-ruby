# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'data_getter'

module GoodData
  module Mixin
    module MetaGetter
      def meta
        data && data['meta']
      end
    end
  end
end
