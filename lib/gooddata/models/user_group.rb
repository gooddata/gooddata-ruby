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
  # Representation of User Group
  #
  # Use user groups to manage user access to dashboards on the GoodData Portal.
  # Create groups to more quickly manage permissions for users with
  # the the same role or who need similar access to dashboards.
  # Groups can be part of groups.
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
        # TODO: Replace with GoodData.get_client_and_project(opts)
        project = opts[:project]
        fail 'Project has to be passed in options' unless project
        fail 'Project has to be of type GoodData::Project' unless project.is_a?(GoodData::Project)
        client = project.client

        results = client.get('/gdc/userGroups', params: { :project => project.pid, :user => opts[:user] }.compact)
        groups = GoodData::Helpers.get_path(results, %w(userGroups items)).map { |i| client.create(GoodData::UserGroup, i, :project => project) }
        id == :all ? groups : groups.find { |g| g.obj_id == id || g.name == id }
      end

      # Create new user group
      #
      # @param data [Hash] Initial data
      # @return [UserGroup] Newly created user group
      def create(data)
        new_data = GoodData::Helpers.deep_dup(EMPTY_OBJECT).tap do |d|
          d['userGroup']['content']['name'] = data[:name]
          d['userGroup']['content']['description'] = data[:description]
          d['userGroup']['content']['project'] = data[:project].respond_to?(:uri) ? data[:project].uri : data[:project]
        end

        client.create(GoodData::UserGroup, GoodData::Helpers.deep_stringify_keys(new_data))
      end

      # Constructs payload for user management/manipulation
      #
      # @return [Hash] Created payload
      def construct_payload(users, operation)
        users = users.is_a?(Array) ? users : [users]

        {
          modifyMembers: {
            operation: operation,
            items: users.map do |user|
              uri = user.respond_to?(:uri) ? user.uri : user
              fail 'You cannot add group as member of another group as of now.' if uri =~ %r{^\/gdc\/userGroups\/}
              uri
            end
          }
        }
      end

      # URI used for membership manipulation/managementv
      #
      # @param client [Client] Client used for communication with platform
      # @param users [User | String | Array<User> | Array<String>] User(s) to be modified
      # @param operation [String] Operation to be performed - ADD, SET, REMOVE
      # @param uri [String] URI to be used for operation
      # @return [String] URI used for membership manipulation/management
      def modify_users(client, users, operation, uri)
        payload = construct_payload(users, operation)
        client.post(uri, payload)
      end
    end

    # Initialize object with json
    #
    # @return [UserGroup] User Group object initialized with json
    def initialize(json)
      @json = json
      self
    end

    # Add member(s) to user group
    #
    # @param [String | User | Array<User>] Users to add to user group
    # @return [nil] Nothing is returned
    def add_members(user)
      UserGroup.modify_users(client, user, 'ADD', uri_modify_members)
    end

    alias_method :add_member, :add_members

    # Gets user group name
    #
    # @return [String] User group name
    def name
      content['name']
    end

    # Sets user group name
    #
    # @param name [String] New user group name
    # @return [String] New user group name
    def name=(name)
      content['name'] = name
      name
    end

    # Gets user group description
    #
    # @return [String] User group description
    def description
      content['description']
    end

    # Sets user group description
    #
    # @param name [String] New user group description
    # @return [String] New user group description
    def description=(name)
      content['description'] = name
    end

    # Gets Users with this Role
    #
    # @return [Array<GoodData::Profile>] List of users
    def members
      url = GoodData::Helpers.get_path(data, %w(links members))
      return [] unless url
      Enumerator.new do |y|
        loop do
          res = client.get url
          res['userGroupMembers']['paging']['next']
          res['userGroupMembers']['items'].each do |member|
            case member.keys.first
            when 'user'
              y << client.create(GoodData::Profile, client.get(GoodData::Helpers.get_path(member, %w(user links self))), :project => project)
            when 'userGroup'
              y << client.create(UserGroup, client.get(GoodData::Helpers.get_path(member, %w(userGroup links self))), :project => project)
            end
          end
          url = res['userGroupMembers']['paging']['next']
          break unless url
        end
      end
    end

    # Verifies if user is in a group or any nested group and returns true if it does
    #
    # @return [Boolean] Retruns true if member is member of the group or any of its members
    def member?(a_member)
      # could be better on API directly?
      uri = a_member.respond_to?(:uri) ? a_member.uri : a_member
      members.map(&:uri).include?(uri)
    end

    # Save user group
    # New group is created if needed else existing one is updated
    #
    # @return [UserGroup] Created or updated user group
    def save
      res = if uri
              # get rid of unsupprted keys
              data = json['userGroup']
              client.put(uri, 'userGroup' => data.except('meta', 'links'))
            else
              client.post('/gdc/userGroups', @json)
            end
      @json = client.get(res['uri'])
      self
    end

    # Remove member(s) from user group
    #
    # @param [String | User | Array<User>] Users to remove from user group
    # @return [nil] Nothing is returned
    def remove_members(user)
      UserGroup.modify_users(client, user, 'REMOVE', uri_modify_members)
    end

    alias_method :remove_member, :remove_members

    # Set member(s) to user group.
    # Only users passed to this call will be new members of user group.
    # Old members not passed to this method will be removed!
    #
    # @param [String | User | Array<User>] Users to set as members of user group
    # @return [nil] Nothing is returned
    def set_members(user) # rubocop:disable Style/AccessorMethodName
      UserGroup.modify_users(client, user, 'SET', uri_modify_members)
    end

    alias_method :set_member, :set_members

    # URI used for membership manipulation/management
    #
    # @return [String] URI used for membership manipulation/management
    def uri_modify_members
      links['modifyMembers']
    end

    # Is it a user group?
    #
    # @return [Boolean] Return true if it is a user group
    def user_group?
      true
    end

    # Checks if two user groups are same
    #
    # @return [Boolean] Return true if the two groups are same
    def ==(other)
      uri == other.uri
    end
  end
end
