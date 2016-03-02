# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'multi_json'
require 'pmap'

require_relative 'project'
require_relative 'project_role'

require_relative '../rest/object'

module GoodData
  class Membership < Rest::Resource
    attr_reader :json

    ASSIGNABLE_MEMBERS = [
      :email,
      :first_name,
      :last_name,
      :login,
      :phone,
      :status,
      :title
    ]

    class << self
      # Apply changes to object.
      #
      # @param obj [GoodData::User] Object to be modified
      # @param changes [Hash] Hash with modifications
      # @return [GoodData::User] Modified object
      # def apply(obj, changes)
      #   changes.each do |param, val|
      #     next unless ASSIGNABLE_MEMBERS.include? param
      #     obj.send("#{param}=", val)
      #   end
      #   obj
      # end
      def create(data, options = { client: GoodData.connection })
        c = client(options)
        json = {
          'user' => {
            'content' => {
              'email' => data[:email] || data[:login],
              'login' => data[:login],
              'firstname' => data[:first_name],
              'lastname' => data[:last_name],
              'userRoles' => ['editor'],
              'password' => data[:password],
              'domain' => data[:domain],
              # And following lines are even much more ugly hack
              # 'authentication_modes' => ['sso', 'password']
            },
            'links' => {},
            'meta' => {}
          }
        }
        json['user']['links']['self'] = data[:uri] if data[:uri]
        c.create(self, json)
      end

      def diff_list(list_1, list_2)
        GoodData::Helpers.diff(list_1, list_2, key: :login)
      end
    end

    def initialize(json)
      @json = json
    end

    # Checks objects for equality
    #
    # @param right [GoodData::User] Project to compare with
    # @return [Boolean] True if same else false
    def ==(other)
      return false unless other.respond_to?(:to_hash)
      to_hash == other.to_hash
      # res = true
      # ASSIGNABLE_MEMBERS.each do |k|
      #   l_val = send("#{k}")
      #   r_val = other.send("#{k}")
      #   res = false if l_val != r_val
      # end
      # res
    end

    # Checks objects for non-equality
    #
    # @param right [GoodData::User] Project to compare with
    # @return [Boolean] True if different else false
    def !=(other)
      !(self == other)
    end

    # Apply changes to object.
    #
    # @param changes [Hash] Hash with modifications
    # @return [GoodData::User] Modified object
    # def apply(changes)
    #   GoodData::User.apply(self, changes)
    # end

    # Gets the contributor
    #
    # @return [String] Contributor
    def contributor
      url = @json['user']['meta']['contributor']
      data = client.get url
      client.create(GoodData::Membership, data)
    end

    # Gets date when created
    #
    # @return [DateTime] Created date
    def created
      Time.parse(@json['user']['meta']['created'])
    end

    # Is the member deleted?
    #
    # @return [Boolean] true if he is deleted
    def deleted?
      !(login =~ /^deleted-/).nil?
    end

    # Gets hash representing diff of users
    #
    # @param user [GoodData::User] Another profile to compare with
    # @return [Hash] Hash representing diff
    def diff(user)
      GoodData::User.diff(self, user)
    end

    # Gets the email
    #
    # @return [String] Email address
    def email
      @json['user']['content']['email'] || ''
    end

    # Sets the email
    #
    # @param new_email [String] New email to be assigned
    def email=(new_email)
      @json['user']['content']['email'] = new_email
    end

    # Gets the first name
    #
    # @return [String] First name
    def first_name
      @json['user']['content']['firstname'] || ''
    end

    # Sets the first name
    #
    # @param new_first_name [String] New first name to be assigned
    def first_name=(new_first_name)
      @json['user']['content']['firstname'] = new_first_name
    end

    # Gets the invitations
    #
    # @return [Array<GoodData::Invitation>] List of invitations
    def invitations
      res = []

      tmp = client.get @json['user']['links']['invitations']
      tmp['invitations'].each do |_invitation|
        # TODO: Something is missing here
      end

      res
    end

    # Gets the last name
    #
    # @return [String] Last name
    def last_name
      @json['user']['content']['lastname'] || ''
    end

    # Sets the last name
    #
    # @param new_last_name [String] New last name to be assigned
    def last_name=(new_last_name)
      @json['user']['content']['lastname'] = new_last_name
    end

    # Gets the login
    #
    # @return [String] Login
    def login
      @json['user']['content']['login'] || ''
    end

    # Sets the last name
    #
    # @param new_login [String] New login to be assigned
    def login=(new_login)
      @json['user']['content']['login'] = new_login
    end

    # Gets user raw object ID
    #
    # @return [String] Raw Object ID
    def obj_id
      uri.split('/').last
    end

    # Gets the permissions
    #
    # @return [Hash] Hash with permissions
    def permissions
      res = {}

      tmp = client.get @json['user']['links']['permissions']
      tmp['associatedPermissions']['permissions'].each do |permission_name, permission_value|
        res[permission_name] = permission_value
      end

      res
    end

    # Gets the phone number
    #
    # @return [String] Phone number
    def phone
      @json['user']['content']['phonenumber'] || ''
    end

    # Sets the phone number
    #
    # @param new_phone_number [String] New phone number to be assigned
    def phone=(new_phone_number)
      @json['user']['content']['phonenumber'] = new_phone_number
    end

    # Gets profile of this membership
    def profile
      raw = client.get @json['user']['links']['self']
      client.create(GoodData::Profile, raw)
    end

    # Gets URL of profile membership
    def profile_url
      @json['user']['links']['self']
    end

    # # Gets project which this membership relates to
    # def project
    #   raw = client.get project_url
    #   client.create(GoodData::Project, raw)
    # end

    # Gets project id
    def project_id
      @json['user']['links']['roles'].split('/')[3]
    end

    # Gets project url
    def project_url
      @json['user']['links']['roles'].split('/')[0..3].join('/')
    end

    # Gets the projects of user
    #
    # @return [Array<GoodData::Project>] Array of projets
    def projects
      tmp = client.get @json['user']['links']['projects']
      tmp['projects'].map do |project_meta|
        project_uri = project_meta['project']['links']['self']
        project = client.get project_uri
        client.create(GoodData::Project, project)
      end
    end

    # Gets first role
    #
    # @return [GoodData::ProjectRole] Array of project roles
    def role
      roles && roles.first
    end

    # Gets the project roles of user
    #
    # @return [Array<GoodData::ProjectRole>] Array of project roles
    def roles
      roles_link = GoodData::Helpers.get_path(@json, %w(user links roles))
      return unless roles_link
      tmp = client.get roles_link
      tmp['associatedRoles']['roles'].pmap do |role_uri|
        role = client.get role_uri
        client.create(GoodData::ProjectRole, role)
      end
    end

    # Gets the status
    #
    # @return [String] Status
    def status
      @json['user']['content']['status'] || ''
    end

    # Gets the title
    #
    # @return [String] User title
    def title
      @json['user']['meta']['title'] || ''
    end

    # Sets the title
    #
    # @param new_title [String] New title to be assigned
    def title=(new_title)
      @json['user']['content']['title'] = new_title
    end

    # Gets the date when updated
    #
    # @return [DateTime] Date of last update
    def updated
      DateTime.parse(@json['user']['meta']['updated'])
    end

    # Gets the object URI
    #
    # @return [String] Object URI
    def uri
      links['self']
    end

    # Enables membership
    #
    # @return [GoodData::Membership] returns self
    def enable
      self.status = 'ENABLED'
      self
    end

    # Is the member enabled?
    #
    # @return [Boolean] true if it is enabled
    def enabled?
      status == 'ENABLED'
    end

    # Disables membership
    #
    # @return [GoodData::Membership] returns self
    def disable
      self.status = 'DISABLED'
      self
    end

    # Is the member enabled?
    #
    # @return [Boolean] true if it is disabled
    def disabled?
      !enabled?
    end

    def data
      data = @json || {}
      data['user'] || {}
    end

    def name
      (first_name || '') + (last_name || '')
    end

    def meta
      data['meta'] || {}
    end

    def links
      data['links'] || {}
    end

    def content
      data['content'] || {}
    end

    def to_hash
      tmp = GoodData::Helpers.symbolize_keys(content.merge(meta).merge('uri' => uri))
      [
        [:userRoles, :role],
        [:companyName, :company_name],
        [:phoneNumber, :phone_number],
        [:firstname, :first_name],
        [:lastname, :last_name],
        [:authenticationModes, :authentication_modes]
      ].each do |vals|
        wire, rb = vals
        tmp[rb] = tmp[wire]
        tmp.delete(wire)
      end
      tmp
    end

    def user_groups
      project.user_groups(:all, user: obj_id)
    end

    private

    # Sets status to 'ENABLED' or 'DISABLED'
    def status=(new_status)
      payload = {
        'user' => {
          'content' => {
            'status' => new_status.to_s.upcase,
            'userRoles' => @json['user']['content']['userRoles']
          },
          'links' => {
            'self' => uri
          }
        }
      }

      res = client.post("/gdc/projects/#{project_id}/users", payload)
      fail 'Update failed' unless res['projectUsersUpdateResult']['failed'].empty?
      @json['user']['content']['status'] = new_status.to_s.upcase
      self
    end
  end
end
