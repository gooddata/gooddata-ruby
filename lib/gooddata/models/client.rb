# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../mixins/data_property_reader'
require_relative '../mixins/links'
require_relative '../mixins/rest_resource'
require_relative '../mixins/uri_getter'

module GoodData
  class Client < Rest::Resource
    data_property_reader 'id'

    include Mixin::Links
    include Mixin::UriGetter

    attr_accessor :segment

    # Initializes object instance from raw wire JSON
    #
    # @param json Json used for initialization
    def initialize(json, opts = { :segment => nil })
      super(opts)
      @json = json
      @segment = opts[:segment]
    end

    def project
      res = client.get(project_uri)
      client.factory.create(GoodData::Project, res)
    end

    def project_uri
      data && data['project']
    end

    def segment
      segment_data = client.get(data['segment'])
      client.factory.create(GoodData::Segment, segment_data)
    end
  end
end
