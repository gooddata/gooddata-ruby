# encoding: UTF-8

require_relative 'account_settings'

module GoodData
  class ProjectRole
    def initialize(json)
      @json = json
    end

    # Gets Project Role Identifier
    #
    # @returns [string] Project Role
    def identifier
      @json['projectRole']['meta']['identifier']
    end

    # Gets Project Role Author
    #
    # @returns [GoodData::AccountSettings] Project Role author
    def author
      url = @json['projectRole']['meta']['author']
      tmp = GoodData.get url
      GoodData::AccountSettings.new(tmp)
    end

    # Gets Project Role Contributor
    #
    # @returns [GoodData::AccountSettings] Project Role Contributor
    def contributor
      url = @json['projectRole']['meta']['contributor']
      tmp = GoodData.get url
      GoodData::AccountSettings.new(tmp)
    end

    # Gets DateTime time when created
    #
    # @returns [DateTime] Date time of creation
    def created
      DateTime.parse(@json['projectRole']['meta']['created'])
    end

    # Gets Project Role Permissions
    #
    # @returns [string] Project Role
    def permissions
      @json['projectRole']['permissions']
    end

    # Gets Project Role Title
    #
    # @returns [string] Project Role Title
    def title
      @json['projectRole']['meta']['title']
    end

    # Gets Project Role Summary
    #
    # @returns [string] Project Role Summary
    def summary
      @json['projectRole']['meta']['summary']
    end

    # Gets DateTime time when updated
    #
    # @returns [DateTime] Date time of last update
    def updated
      DateTime.parse(@json['projectRole']['meta']['updated'])
    end

    # Gets Users with this Role
    #
    # @returns [Array<GoodData::AccountSettings>] List of users
    def users
      res = []
      url = @json['projectRole']['links']['roleUsers']
      tmp = GoodData.get url
      tmp['associatedUsers']['users'].each do |user_url|
        user = GoodData.get user_url
        res << GoodData::AccountSettings.new(user)
      end
      res
    end

    # Gets Raw object URI
    #
    # @returns [string] URI of this project role
    def uri
      @json['projectRole']['links']['roleUsers'].split('/')[0...-1].join('/')
    end
  end
end
