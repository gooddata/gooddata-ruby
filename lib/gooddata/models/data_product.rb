# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../rest/resource'

module GoodData
  class DataProduct < Rest::Resource
    attr_accessor :domain

    def initialize(json)
      @json = json
    end

    def clients
      json = client.get(data['links']['clients'])

      json['clients']['items'].map do |val|
        client.create(GoodData::Client, val, domain: domain)
      end
    end

    def segments
      json = client.get(data['links']['segments'])

      json['segments']['items'].map do |val|
        client.create(GoodData::Segment, val, domain: domain, data_product: self)
      end
    end
  end
end
