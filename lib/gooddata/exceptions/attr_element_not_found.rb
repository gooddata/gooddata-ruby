# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  # Project Not Found
  class AttributeElementNotFound < RuntimeError
    DEFAULT_MSG = 'Attribute element "%s" was not found'

    def initialize(value, _msg = DEFAULT_MSG)
      super(sprintf(DEFAULT_MSG, value))
    end
  end
end
