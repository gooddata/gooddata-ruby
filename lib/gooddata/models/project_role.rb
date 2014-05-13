# encoding: UTF-8

require_relative 'account_settings'

module GoodData
  class ProjectRole
    def initialize(json)
      @json = json
    end

    # Gets Project Role Identifier
    #
    # @return [string] Project Role
    def identifier
      @json['projectRole']['meta']['identifier']
    end

    # Gets Project Role Author
    #
    # @return [GoodData::AccountSettings] Project Role author
    def author
      url = @json['projectRole']['meta']['author']
      tmp = GoodData.get url
      GoodData::AccountSettings.new(tmp)
    end

    # Gets Project Role Contributor
    #
    # @return [GoodData::AccountSettings] Project Role Contributor
    def contributor
      url = @json['projectRole']['meta']['contributor']
      tmp = GoodData.get url
      GoodData::AccountSettings.new(tmp)
    end

    # Gets DateTime time when created
    #
    # @return [DateTime] Date time of creation
    def created
      DateTime.parse(@json['projectRole']['meta']['created'])
    end

    # Gets Project Role Permissions
    #
    # @return [string] Project Role
    def permissions
      @json['projectRole']['permissions']
    end

    # Gets Project Role Title
    #
    # @return [string] Project Role Title
    def title
      @json['projectRole']['meta']['title']
    end

    # Gets Project Role Summary
    #
    # @return [string] Project Role Summary
    def summary
      @json['projectRole']['meta']['summary']
    end

    # Gets DateTime time when updated
    #
    # @return [DateTime] Date time of last update
    def updated
      DateTime.parse(@json['projectRole']['meta']['updated'])
    end

    # Gets Users with this Role
    #
    # @return [Array<GoodData::AccountSettings>] List of users
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
    # @return [string] URI of this project role
    def uri
      @json['projectRole']['links']['roleUsers'].split('/')[0...-1].join('/')
    end
  end
end
