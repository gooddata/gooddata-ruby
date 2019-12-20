# encoding: UTF-8
#
# Copyright (c) 2010-2019 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module CloudResources
    class CloudResourceClient
      def self.inherited(klass)
        @descendants ||= []
        @descendants << klass
      end

      def self.descendants
        @descendants || []
      end

      def realize_query(_params)
        raise NotImplementedError, 'Must be implemented in subclass'
      end
    end
  end
end
