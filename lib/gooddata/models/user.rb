# encoding: UTF-8

require_relative 'project'
require_relative 'project_role'

module GoodData
  class User
    attr_reader :json
    def initialize(json)
      @json = json
    end

    def author
      # TODO: Return object instead
      @json['user']['meta']['author']
    end

    def contributor
      # TODO: Return object instead
      @json['user']['meta']['contributor']
    end

    def created
      DateTime.parse(@json['user']['meta']['created'])
    end

    def email
      @json['user']['content']['email'] || ''
    end

    def first_name
      @json['user']['content']['firstname'] || ''
    end

    def invitations
      res = []

      tmp = GoodData.get @json['user']['links']['invitations']
      tmp['invitations'].each do |invitation|
      end

      res
    end

    def last_name
      @json['user']['content']['lastname'] || ''
    end

    def login
      @json['user']['content']['login'] || ''
    end

    def obj_id
      uri.split('/').last
    end

    def permissions
      res = {}

      tmp = GoodData.get @json['user']['links']['permissions']
      tmp['associatedPermissions']['permissions'].each do |permission_name, permission_value|
        res[permission_name] = permission_value
      end

      res
    end

    def phone
      @json['user']['content']['phonenumber'] || ''
    end

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

    def roles
      res = []

      tmp = GoodData.get @json['user']['links']['roles']
      tmp['associatedRoles']['roles'].each do |role_uri|
        role = GoodData.get role_uri
        res << GoodData::ProjectRole.new(role)
      end

      res
    end

    def status
      @json['user']['content']['status'] || ''
    end

    def title
      @json['user']['meta']['title'] || ''
    end

    def updated
      DateTime.parse(@json['user']['meta']['updated'])
    end

    def uri
      @json['user']['links']['self']
    end
  end
end
