# encoding: UTF-8

require 'multi_json'

require_relative 'project'
require_relative 'project_role'

module GoodData
  class User
    attr_reader :json

    def initialize(json)
      @json = json
    end

    # Gets author (person who created)  of this object
    #
    # @return [String] Author
    def author
      url = @json['user']['meta']['author']
      data = GoodData.get url
      GoodData::User.new(data)
    end

    # Gets the contributor
    #
    # @return [String] Contributor
    def contributor
      url = @json['user']['meta']['contributor']
      data = GoodData.get url
      GoodData::User.new(data)
    end

    # Gets date when created
    #
    # @return [DateTime] Created date
    def created
      Time.parse(@json['user']['meta']['created'])
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

      tmp = GoodData.get @json['user']['links']['invitations']
      tmp['invitations'].each do |invitation|
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

      tmp = GoodData.get @json['user']['links']['permissions']
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

    # Gets the projects of user
    #
    # @return [Array<GoodData::Project>] Array of projets
    def projects
      res = []

      tmp = GoodData.get @json['user']['links']['projects']
      tmp['projects'].each do |project_meta|
        project_uri = project_meta['project']['links']['self']
        project = GoodData.get project_uri
        res << GoodData::Project.new(project)
      end

      res
    end

    # Gets the project roles of user
    #
    # @return [Array<GoodData::ProjectRole>] Array of project roles
    def roles
      res = []

      tmp = GoodData.get @json['user']['links']['roles']
      tmp['associatedRoles']['roles'].each do |role_uri|
        role = GoodData.get role_uri
        res << GoodData::ProjectRole.new(role)
      end

      res
    end

    # Gets the status
    #
    # @return [String] Status
    def status
      @json['user']['content']['status'] || ''
    end

    # Sets the status
    #
    # @param new_status [String] New phone number to be assigned
    def status=(new_status)
      @json['user']['content']['status'] = new_status
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
      @json['user']['links']['self']
    end

    # Disables an user in the provided project
    #
    # @return result from post execution
    def disable(project)
      payload = {
        'user' => {
          'content' => {
            'status' => 'DISABLED',
            'userRoles' => @json['user']['content']['userRoles']
          },
          'links' => {
            'self' => uri
          }
        }
      }

      @json = GoodData.post("/gdc/projects/#{project.obj_id}/users", payload)
    end
  end
end
