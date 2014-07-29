# encoding: UTF-8

require_relative 'profile'

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
    # @return [GoodData::Profile] Project Role author
    def author
      url = @json['projectRole']['meta']['author']
      tmp = GoodData.get url
      GoodData::Profile.new(tmp)
    end

    # Gets Project Role Contributor
    #
    # @return [GoodData::Profile] Project Role Contributor
    def contributor
      url = @json['projectRole']['meta']['contributor']
      tmp = GoodData.get url
      GoodData::Profile.new(tmp)
    end

    # Gets DateTime time when created
    #
    # @return [DateTime] Date time of creation
    def created
      Time.parse(@json['projectRole']['meta']['created'])
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
      Time.parse(@json['projectRole']['meta']['updated'])
    end

    # Gets Users with this Role
    #
    # @return [Array<GoodData::Profile>] List of users
    def users
      res = []
      url = @json['projectRole']['links']['roleUsers']
      tmp = GoodData.get url
      tmp['associatedUsers']['users'].each do |user_url|
        user = GoodData.get user_url
        res << GoodData::Profile.new(user)
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
