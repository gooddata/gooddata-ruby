# encoding: UTF-8

require_relative 'profile'

require_relative '../mixins/mixins'

module GoodData
  class ProjectRole
    attr_accessor :json

    include GoodData::Mixin::MetaGetter
    include GoodData::Mixin::DataGetter

    class << self
      include GoodData::Mixin::RootKeySetter
      include GoodData::Mixin::DataPropertyReader
      include GoodData::Mixin::DataPropertyWriter
      include GoodData::Mixin::MetaPropertyReader
      include GoodData::Mixin::MetaPropertyWriter
    end

    ProjectRole.root_key :projectRole

    include GoodData::Mixin::RootKeyGetter
    include GoodData::Mixin::Author
    include GoodData::Mixin::Contributor
    include GoodData::Mixin::Timestamps

    def initialize(json)
      @json = json
    end

    ProjectRole.data_property_reader :permissions

    ProjectRole.metadata_property_reader :identifier, :title, :summary

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
