# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../rest/resource'

module GoodData
  module LifeCycle
    class Client < Rest::Resource
      attr_reader :json
      attr_accessor :domain

      include GoodData::Mixin::RestResource
      root_key :segment

      CLIENT_TEMPLATE = {
        client: {
          id: nil,
          segment: nil,
          project: nil
        }
      }

      class << self
        def [](id, opts = {})
          domain = opts[:domain]
          segment = opts[:segment]
          fail ArgumentError, 'No :domain specified' if domain.nil?
          fail ArgumentError, 'No :segment specified' if domain.nil?

          client = domain.client
          fail ArgumentError, 'No client specified' if client.nil?

          base_uri = domain.segments_uri + "/clients?segment=#{CGI.escape(segment.segment_id)}"
          tenants_uri = id == :all ? base_uri : base_uri + "&name=#{CGI.escape(id)}"
          e = Enumerator.new do |y|
            loop do
              res = client.get tenants_uri
              res['clients']['paging']['next']
              res['clients']['items'].each do |i|
                p = i['client']['project']
                tenant = client.create(GoodData::LifeCycle::Client, i.merge('domain' => domain))
                tenant.project = p
                y << tenant
              end
              url = res['clients']['paging']['next']
              break unless url
            end
          end
          id == :all ? e : e.first
        end

        # Creates new client from parameters passed
        #
        # @param options [Hash] Optional options
        # @return [GoodData::Schedule] New GoodData::Schedule instance
        def create(data = {}, options = {})
          segment = options[:segment]
          domain = segment.domain
          tenant = client.create(GoodData::LifeCycle::Client, GoodData::Helpers.deep_stringify_keys(CLIENT_TEMPLATE.merge(domain: domain)))
          tenant.tap do |s|
            s.project = data[:project]
            s.client_id = data[:id]
            s.segment = segment.uri
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
      def client_id
        GoodData::Helpers.get_path(json, %w(client id))
      end

      def client_id=(a_name)
        @json['client']['id'] = a_name
        self
      end

      # Setter for the project this client has set
      #
      # @param a_project [String|GoodData::Project] Id or an instance of a project
      # @return [GoodData::Cliet] Returns the instance of the client
      def project=(a_project)
        @json['client']['project'] = a_project.respond_to?(:uri) ? a_project.uri : a_project
        self
      end

      # Project URI this client has set
      #
      # @return [String] Returns the URI of the project this client has set
      def project_uri
        GoodData::Helpers.get_path(json, %w(client project))
      end

      # Project this client has set
      #
      # @return [GoodData::Project] Returns the instance of the client's project
      def project
        client.projects(project_uri)
      end

      # Segment id setter which this client is connected to.
      #
      # @param a_segment [String] Id of the segment.
      # @return [GoodData::LifeCycle::Client] Returns the instance of the client
      def segment=(a_segment)
        @json['client']['segment'] = a_segment.respond_to?(:uri) ? a_segment.uri : a_segment
        self
      end

      # Segment this client is connected to.
      #
      # @return [GoodData::LifeCycle::Segment] Segment
      def segment
        domain.segments(GoodData::Helpers.last_uri_part(segment_uri))
      end

      # Segment URI this client is connected to.
      #
      # @return [String] Segment URI
      def segment_uri
        GoodData::Helpers.get_path(json, %w(client segment))
      end

      # Client URI
      #
      # @return [String] URI
      def uri
        GoodData::Helpers.get_path(json, %w(client links self))
      end

      # Creates or updates a client instance on the API.
      #
      # @return [GoodData::LifeCycle::Client] Client instance
      def save
        if uri
          client.put(uri, json)
        else
          res = client.post(domain.segments_uri + '/clients', json)
          @json = res
        end
        self
      end

      # Deletes a client instance on the API.
      #
      # @return [GoodData::LifeCycle::Client] Segment instance
      def delete
        client.delete(uri) if uri
      end
    end
  end
end
