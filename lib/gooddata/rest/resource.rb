# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'object'

module GoodData
  module Rest
    # Base class for REST resources implementing (at least 'somehow') full CRUD
    #
    # IS responsible for wrapping full CRUD interface
    class Resource < Object
      # Default constructor passing all arguments to parent
      def initialize(opts = {})
        super
      end
    end
  end
end
