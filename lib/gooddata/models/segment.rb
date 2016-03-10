# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative './client'
require_relative './domain'
require_relative '../models/client_synchronization_result'

require_relative '../mixins/data_property_reader'
require_relative '../mixins/links'
require_relative '../mixins/rest_resource'
require_relative '../mixins/uri_getter'

module GoodData
  class Segment < Rest::Resource
    SYNCHRONIZE_URI = '/gdc/domains/%s/segments/%s/synchronizeClients'

    attr_accessor :domain

    data_property_reader 'id'

    include Mixin::Links
    include Mixin::UriGetter

    SEGMENT_TEMPLATE = {
      :segment => {
        :id => nil,
        :masterProject => nil
      }
    }

    class << self
      # Returns list of all segments or a particular segment
      #
      # @param id [String|Symbol] Uri of the segment required or :all for all segments.
      # @return [Array<GoodData::Segment>] List of segments for a particular domain
      def [](id, opts = {})
        domain = opts[:domain]
        fail ArgumentError, 'No :domain specified' if domain.nil?

        client = domain.client
        fail ArgumentError, 'No client specified' if client.nil?

        if id == :all
          GoodData::Segment.all(opts)
        else
          result = client.get(domain.segments_uri + "/segments/#{CGI.escape(id)}")
          client.create(GoodData::Segment, result.merge('domain' => domain))
        end
      end

      # Returns list of all segments for domain
      #
      # @param opts [Hash] Options. Should contain :domain for which you want to get the segments.
      # @return [Array<GoodData::Segment>] List of segments for a particular domain
      def all(opts = {})
        domain = opts[:domain]
        fail 'Domain has to be passed in options' unless domain
        client = domain.client

        results = client.get(domain.segments_uri + '/segments')
        GoodData::Helpers.get_path(results, %w(segments items)).map { |i| client.create(GoodData::Segment, i.merge('domain' => domain)) }
      end

      # Creates new segment from parameters passed
      #
      # @param data [Hash] Data for segment namely :segment_id and :master_project is accepted. Master_project can be given as either a PID or a Project instance
      # @param options [Hash] Trigger of schedule. Can be cron string or reference to another schedule.
      # @return [GoodData::Segment] New Segment instance
      def create(data = {}, options = {})
        segment_id = data[:segment_id]
        fail 'Custom ID has to be provided' if segment_id.blank?
        client = options[:client]
        segment = client.create(GoodData::Segment, GoodData::Helpers.deep_stringify_keys(SEGMENT_TEMPLATE).merge('domain' => options[:domain]))
        segment.tap do |s|
          s.segment_id = segment_id
          s.master_project = data[:master_project]
        end
      end
    end

    def initialize(data)
      super
      @domain = data.delete('domain')
      @json = data
    end

    # Segment id getter for the Segment. Called segment_id since id is a reserved word in ruby world
    #
    # @return [String] Segment id
    def segment_id
      data['id']
    end

    # Segment id setter for the Segment. Called segment_id since id is a reserved word in ruby world
    #
    # @param an_id [String] Id of the segment.
    # @return [String] Segment id
    def segment_id=(an_id)
      data['id'] = an_id
      self
    end

    # Master project id getter for the Segment.
    #
    # @return [String] Segment id
    def master_project=(a_project)
      data['masterProject'] = a_project.respond_to?(:uri) ? a_project.uri : a_project
      self
    end

    alias_method :master=, :master_project=

    # Master project id getter for the Segment.
    #
    # @return [String] Project uri
    def master_project_id
      GoodData::Helpers.last_uri_part(master_project_uri)
    end

    alias_method :master_id, :master_project_id

    # Master project uri getter for the Segment.
    #
    # @return [String] Project uri
    def master_project_uri
      data['masterProject']
    end

    alias_method :master_uri, :master_project_uri

    # Master project getter for the Segment. It returns the instance not just the URI
    #
    # @return [GoodData::Project] Project associated with the segment
    def master_project
      client.projects(master_project_uri)
    end

    alias_method :master, :master_project

    def create_client(data)
      client = GoodData::Client.create(data, segment: self)
      client.save
    end

    # Returns all the clients associated with the segment. Since this is potentially paging operation it returns an Enumerable.
    #
    # @return [Enumerable] Clients associated with the segment
    def clients(tenant_id = :all)
      GoodData::Client[tenant_id, domain: domain, segment: self]
    end

    # Creates or updates a segment instance on the API.
    #
    # @return [GoodData::Segment] Segment instance
    def save
      if uri
        client.put(uri, json)
      else
        res = client.post(domain.segments_uri + '/segments', json)
        @json = res
      end
      self
    end

    # Runs async process that walks thorugh segments and provisions projects if necessary.
    #
    # @return [Array] Returns array of results
    def synchronize_clients
      sync_uri = SYNCHRONIZE_URI % [domain.obj_id, id]
      res = client.post sync_uri, nil

      # wait until the instance is created
      res = client.poll_on_response(res['asyncTask']['links']['poll'], :sleep_interval => 1) do |r|
        r['synchronizationResult'].nil?
      end

      client.create(ClientSynchronizationResult, res)
    end

    # Deletes a segment instance on the API.
    #
    # @return [GoodData::Segment] Segment instance
    def delete(options = {})
      force = options[:force] == true ? true : false
      clients.peach(&:delete) if force
      client.delete(uri) if uri
      self
    rescue RestClient::BadRequest => e
      payload = GoodData::Helpers.parse_http_exception(e)
      case GoodData::Helpers.get_path(payload)
      when 'gdc.c4.conflict.domain.segment.contains_clients'
        throw SegmentNotEmpty
      else
        raise e
      end
    end
  end
end
