# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../rest/rest'
require_relative '../rest/resource'
require_relative '../mixins/author'
require_relative '../mixins/contributor'
require_relative '../mixins/links'
require_relative '../mixins/rest_resource'
require_relative '../mixins/uri_getter'

module GoodData
  class UserGroup < Rest::Resource
    include Mixin::Author
    include Mixin::Contributor
    include Mixin::Links
    include Mixin::UriGetter

    EMPTY_OBJECT = {
      'userGroup' => {
        'content' => {
          'name' => nil,
          'description' => nil,
          'project' => nil
        }
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
        project = opts[:project]
        fail 'Project has to be passed in options' unless project
        fail 'Project has to be of type GoodData::Project' unless project.is_a?(GoodData::Project)
        client = project.client
        results = client.get('/gdc/userGroups', params: { :project => project.pid })
        GoodData::Helpers.get_path(results, %w(userGroups items)).map { |i| client.create(GoodData::UserGroup, i.merge('project' => project)) }
      end

      def create(data)
        new_data = GoodData::Helpers.deep_dup(EMPTY_OBJECT).tap do |d|
          d['userGroup']['content']['name'] = data[:name]
          d['userGroup']['content']['description'] = data[:description]
          d['userGroup']['content']['project'] = data[:project].respond_to?(:uri) ? data[:project].uri : data[:project]
        end
        client.create(GoodData::UserGroup, GoodData::Helpers.deep_stringify_keys(new_data))
      end

      def construct_payload(users, operation)
        users = users.kind_of?(Array) ? users : [users]

        {
          modifyMembers: {
            operation: operation,
            items: users.map do |user|
              user.respond_to?(:uri) ? user.uri : user
            end
          }
        }
      end

      def modify_users(client, users, operation, uri)
        payload = construct_payload(users, operation)
        client.post(uri, payload)
      end

    end

    def initialize(json)
      @json = json
    end

    def add_user(user)
      UserGroup.modify_users(client, user, 'ADD', uri_modify_members)
    end

    alias_method :add_users, :add_user

    def name
      content['name']
    end

    def name=(name)
      content['name'] = name
    end

    def description
      content['description']
    end

    def description=(name)
      content['description'] = name
    end

    # Gets Users with this Role
    #
    # @return [Array<GoodData::Profile>] List of users
    def members(opts = {})
      url = GoodData::Helpers.get_path(data, %w(links members))
      return unless url
      Enumerator.new do |y|
        loop do
          res = client.get url
          res['userGroupMembers']['paging']['next']
          res['userGroupMembers']['items'].each do |member|
            # y << client.create(Execution, execution, :project => project)
            y << member
          end
          url = res['userGroupMembers']['paging']['next']
          puts "url='#{url}'"
          break unless url
        end
      end
    end

    # Gets Raw object URI
    #
    # @return [string] URI of this project role
    # def uri
    #   GoodData::Helpers.get_path(data, %w(links self))
    # end

    def save
      if uri
        # get rid of unsupprted keys
        data = @json['userGroup']
        res = client.put(uri, { 'userGroup' => data.except('meta', 'links') })
        binding.pry
      else
        res = client.post('/gdc/userGroups', @json)
        @json = client.get(res['uri'])
      end
      self
    end

    def remove_user(user)
      UserGroup.modify_users(client, user, 'REMOVE', uri_modify_members)
    end

    alias_method :remove_users, :remove_user

    def set_user(user)
      UserGroup.modify_users(client, user, 'SET', uri_modify_members)
    end

    alias_method :set_users, :set_user

    def uri_modify_members
      links['modifyMembers']
    end

    def ==(other)
      uri == other.uri
    end
  end
end
