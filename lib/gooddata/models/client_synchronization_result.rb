# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative './client_synchronization_result_details'

require_relative '../mixins/data_property_reader'
require_relative '../mixins/links'

require_relative '../rest/resource'

module GoodData
  class ClientSynchronizationResult < Rest::Resource
    include Mixin::Links

    # Initializes object instance from raw wire JSON
    #
    # @param json Json used for initialization
    def initialize(json, opts = {})
      super(opts)
      @json = json
    end

    def details
      res = client.get(links['details'])
      client.create(GoodData::ClientSynchronizationResultDetails, res) if res
    end
  end
end
