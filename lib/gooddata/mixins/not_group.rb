# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Mixin
    module NotUserGroup
      # Returns true if the object is a fact false otherwise
      # @return [Boolean]
      def user_group?
        false
      end
    end
  end
end
