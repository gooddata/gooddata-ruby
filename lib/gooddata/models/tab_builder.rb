# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Model
    class TabBuilder
      def initialize(title)
        @title = title
        @stuff = []
      end

      def add_report(options = {})
        @stuff << { :type => :report }.merge(options)
      end

      def to_hash
        {
          :title => @title,
          :items => @stuff
        }
      end
    end
  end
end
