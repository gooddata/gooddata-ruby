# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../mixins/rest_resource'
require_relative '../mixins/data_property_reader'

module GoodData
  class Segment < Rest::Resource
    data_property_reader 'id'
    attr_reader :domain

    # Initializes object instance from raw wire JSON
    #
    # @param json Json used for initialization
    def initialize(json, opts = { :domain => nil })
      super(opts)
      @json = json
      @domain = opts[:domain]
    end

    def domain=(domain)
      @domain = domain
    end
  end
end

