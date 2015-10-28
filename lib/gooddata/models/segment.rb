# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../rest/resource'

module GoodData
  module LifeCycle
    class Segment < Rest::Resource
      attr_reader :json
      attr_accessor :domain

      include GoodData::Mixin::RestResource
      root_key :segment

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
        # @return [Array<GoodData::LifeCycle::Segment>] List of segments for a particular domain
        def [](id, opts = {})
          domain = opts[:domain]
          fail ArgumentError, 'No :domain specified' if domain.nil?

          client = domain.client
          fail ArgumentError, 'No client specified' if client.nil?

          if id == :all
            GoodData::LifeCycle::Segment.all(opts)
          else
            result = client.get(domain.segments_uri + "/segments/#{CGI.escape(id)}")
            client.create(GoodData::LifeCycle::Segment, result.merge('domain' => domain))
          end
        end

        # Returns list of all segments for domain
        #
        # @param opts [Hash] Options. Should contain :domain for which you want to get the segments.
        # @return [Array<GoodData::LifeCycle::Segment>] List of segments for a particular domain
        def all(opts = {})
          domain = opts[:domain]
          fail 'Domain has to be passed in options' unless domain
          client = domain.client

          results = client.get(domain.segments_uri + '/segments')
          GoodData::Helpers.get_path(results, %w(segments items)).map { |i| client.create(GoodData::LifeCycle::Segment, i.merge('domain' => domain)) }
        end

        # Creates new segment from parameters passed
        #
        # @param data [Hash] Data for segment namely :segment_id and :master_project is accepted. Master_project can be given as either a PID or a Project instance
        # @param options [Hash] Trigger of schedule. Can be cron string or reference to another schedule.
        # @return [GoodData::LifeCycle::Segment] New Segment instance
        def create(data = {}, options = {})
          segment_id = data[:segment_id]
          fail 'Custom ID has to be provided' if segment_id.blank?
          client = options[:client]
          segment = client.create(GoodData::LifeCycle::Segment, GoodData::Helpers.deep_stringify_keys(SEGMENT_TEMPLATE).merge('domain' => options[:domain]))
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
        GoodData::Helpers.get_path(json, %w(segment id))
      end

      # Segment id setter for the Segment. Called segment_id since id is a reserved word in ruby world
      #
      # @param an_id [String] Id of the segment.
      # @return [String] Segment id
      def segment_id=(an_id)
        @json['segment']['id'] = an_id
        self
      end

      # Master project id getter for the Segment.
      #
      # @return [String] Segment id
      def master_project=(a_project)
        @json['segment']['masterProject'] = a_project.respond_to?(:uri) ? a_project.uri : a_project
        self
      end

      # Master project id getter for the Segment.
      #
      # @return [String] Project uri
      def master_project_uri
        GoodData::Helpers.get_path(json, %w(segment masterProject))
      end

      # Master project getter for the Segment. It returns the instance not just the URI
      #
      # @return [GoodData::Project] Project associated with the segment
      def master_project
        client.projects(master_project_uri)
      end

      def create_client(data)
        client = GoodData::LifeCycle::Client.create(data, segment: self)
        client.save
      end

      # Returns all the clients associated with the segment. Since this is potentially paging operation it returns an Enumerable.
      #
      # @return [Enumerable] Clients associated with the segment
      def clients(tenant_id = :all)
        GoodData::LifeCycle::Client[tenant_id, domain: domain, segment: self]
      end

      # Segment URI getter.
      #
      # @return [String] Segment id
      def uri
        GoodData::Helpers.get_path(json, %w(segment links self))
      end

      # Creates or updates a segment instance on the API.
      #
      # @return [GoodData::LifeCycle::Segment] Segment instance
      def save
        if uri
          client.put(uri, json)
        else
          res = client.post(domain.segments_uri + '/segments', json)
          @json = res
        end
        self
      end

      # Deletes a segment instance on the API.
      #
      # @return [GoodData::LifeCycle::Segment] Segment instance
      def delete
        client.delete(uri) if uri
        self
      end
    end
  end
end
