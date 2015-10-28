# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative './client'

require_relative '../mixins/data_property_reader'
require_relative '../mixins/links'

require_relative '../rest/resource'

module GoodData
  class ClientSynchronizationResultDetails < Rest::Resource
    include Mixin::Links

    attr_accessor :synchronization_result

    # Initializes object instance from raw wire JSON
    #
    # @param json Json used for initialization
    def initialize(json, opts = { :synchronization_result => nil })
      super(opts)
      @json = json
      @synchronization_result = opts[:synchronization_result]
    end

    def items
      data['items']
    end

    def next
      paging && paging['next']
    end

    def paging
      data['paging']
    end
  end
end
