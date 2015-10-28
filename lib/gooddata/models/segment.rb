# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative './client'
require_relative '../models/synchronization_result'

require_relative '../mixins/data_property_reader'
require_relative '../mixins/links'
require_relative '../mixins/rest_resource'
require_relative '../mixins/uri_getter'

module GoodData
  class Segment < Rest::Resource
    SYNCHRONIZE_URI = '/gdc/domains/%s/segments/%s/synchronizeClients'

    attr_writer :domain

    data_property_reader 'id'

    include Mixin::Links
    include Mixin::UriGetter

    # Initializes object instance from raw wire JSON
    #
    # @param json Json used for initialization
    def initialize(json, opts = { :domain => nil })
      super(opts)
      @json = json
      @domain = opts[:domain]
    end

    def clients
      clients_uri = links['clients']
      response = clients_uri && client.get(clients_uri)
      clients = (response && response['clients'] && response['clients']['items']) || []
      clients.map do |client_data|
        client.factory.create(GoodData::Client, client_data, :segment => self)
      end
    end

    def domain
      @domain || Domain[links['domain'], :client => client]
    end

    def master
      client.projects(master_uri)
    end

    def master_uri
      data['masterProject']
    end

    def synchronize_clients
      sync_uri = SYNCHRONIZE_URI % [domain.obj_id, id]
      res = client.post sync_uri, nil

      # wait until the instance is created
      res = client.poll_on_response(res['asyncTask']['links']['poll'], :sleep_interval => 1) do |r|
        r['synchronizationResult'].nil?
      end

      client.factory.create(SynchronizationResult, res)
    end
  end
end
