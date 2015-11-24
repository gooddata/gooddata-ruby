# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'object'

require_relative '../mixins/obj_id'
require_relative '../mixins/rest_resource'

module GoodData
  module Rest
    # Base class for REST resources implementing (at least 'somehow') full CRUD
    #
    # IS responsible for wrapping full CRUD interface
    class Resource < Object
      include Mixin::RestResource
      include Mixin::ObjId

      # Default constructor passing all arguments to parent
      def initialize(opts = {})
        super(opts)
      end
    end
  end
end
