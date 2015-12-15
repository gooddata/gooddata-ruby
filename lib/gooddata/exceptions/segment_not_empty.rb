# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'restclient/exceptions'

module GoodData
  # Project Not Found
  class SegmentNotEmpty < RuntimeError
    DEFAULT_MSG = 'Segment you are trying to delete is not empty. Either clean it up or use force: true to force cleanup of clients.'

    def initialize(msg = DEFAULT_MSG)
      super(msg)
    end
  end
end
