# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../rest/resource'

module GoodData
  class DataProduct < Rest::Resource
    include Mixin::UriGetter

    attr_accessor :domain

    ALL_DATA_PRODUCTS_PATH = '/gdc/domains/%{domain_name}/dataproducts'
    ONE_DATA_PRODUCT_PATH = '/gdc/domains/%{domain_name}/dataproducts/%{id}'

    class << self
      def [](id, opts)
        domain = opts[:domain]
        fail ArgumentError, 'No :domain specified' if domain.nil?

        client = domain.client
        fail ArgumentError, 'No client specified' if client.nil?

        if id == :all
          GoodData::DataProduct.all(opts)
        else
          data_products_uri = ONE_DATA_PRODUCT_PATH % { domain_name: domain.name, id: id }

          result = client.get(data_products_uri)
          client.create(GoodData::DataProduct, result.merge('domain' => domain))
        end
      end

      def all(opts = {})
        domain = opts[:domain]
        fail ArgumentError, 'No :domain specified' if domain.nil?

        client = domain.client
        fail ArgumentError, 'No client specified' if client.nil?

        data_products_uri = ALL_DATA_PRODUCTS_PATH % { domain_name: domain.name }

        GoodData::Helpers.get_path(client.get(data_products_uri), %w(dataProducts items)).map do |i|
          client.create(GoodData::DataProduct, i, domain: domain)
        end
      end

      def create(data = {}, options = {})
        fail 'id for data_product has to be provided' if data[:id].blank?
        client = options[:client]
        client.create(GoodData::DataProduct, GoodData::Helpers.stringify_keys(dataProduct: data), domain: options[:domain])
      end
    end

    def initialize(json)
      super
      @json = json
      @domain = json.delete('domain')
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

    def save
      if @json[:uri]
        client.put(uri, json)
      else
        data_products_uri = ALL_DATA_PRODUCTS_PATH % { domain_name: domain.name }
        res = client.post(data_products_uri, json)
        @json = res
      end
      self
    end

    def delete(options = {})
      segments.peach { |s| s.delete(options) }
      client.delete(uri) if uri
      self
    end

    def update_clients(data, options = {})
      if options[:delete_extra] && options[:delete_extra_in_segments]
        fail 'Options delete_extra and delete_extra_in_segments are mutually exclusive.'
      end

      data_products_uri = ONE_DATA_PRODUCT_PATH % { domain_name: domain.name, id: data_product_id }

      payload = data.map do |datum|
        {
          :client => {
            :id => datum[:id],
            :segment => data_products_uri + '/segments/' + datum[:segment]
          }
        }.tap do |h|
          h[:client][:project] = datum[:project] if datum.key?(:project)
        end
      end

      if options[:delete_extra]
        res = client.post(data_products_uri + '/updateClients?deleteExtra=true', updateClients: { items: payload })
      elsif options[:delete_extra_in_segments]
        segments_to_delete_in = options[:delete_extra_in_segments]
                                  .map { |segment| CGI.escape(segment) }
                                  .join(',')
        uri = data_products_uri + "/updateClients?deleteExtraInSegments=#{segments_to_delete_in}"
        res = client.post(uri, updateClients: { items: payload })
      else
        res = client.post(data_products_uri + '/updateClients', updateClients: { items: payload })
      end
      data = GoodData::Helpers.get_path(res, ['updateClientsResponse'])
      if data
        result = data.flat_map { |k, v| v.map { |h| GoodData::Helpers.symbolize_keys(h.merge('type' => k)) } }
        result.select { |r| r[:status] == 'DELETED' }.peach { |r| r[:originalProject] && client.delete(r[:originalProject]) } if options[:delete_projects]
        result
      else
        []
      end
    end

    def data_product_id
      data['id']
    end

    def data_product_id=(new_id)
      data['id'] = new_id
    end

    def create_segment(data)
      segment = GoodData::Segment.create(data, domain: domain, client: domain.client)
      segment.data_product = self
      segment.save
    end
  end
end
