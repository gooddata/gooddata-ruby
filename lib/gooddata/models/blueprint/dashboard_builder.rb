# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Model
    class DashboardBuilder
      def initialize(title)
        @title = title
        @tabs = []
      end

      def add_tab(tab, &block)
        tb = TabBuilder.new(tab)
        block.call(tb)
        @tabs << tb
        tb
      end

      def to_hash
        {
          :name => @name,
          :tabs => @tabs.map(&:to_hash)
        }
      end
    end
  end
end
