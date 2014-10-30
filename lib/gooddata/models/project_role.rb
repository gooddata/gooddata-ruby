# encoding: UTF-8

require 'pmap'

require_relative 'profile'

require_relative '../rest/rest'

require_relative '../mixins/rest_resource'

module GoodData
  class ProjectRole < GoodData::Rest::Object
    attr_accessor :json

    include GoodData::Mixin::RestResource

    root_key :projectRole

    include GoodData::Mixin::Author
    include GoodData::Mixin::Contributor
    include GoodData::Mixin::Timestamps

    def initialize(json)
      @json = json
    end

    data_property_reader :permissions

    metadata_property_reader :identifier, :title, :summary

    # Gets Users with this Role
    #
    # @return [Array<GoodData::Profile>] List of users
    def users
      url = data['links']['roleUsers']
      tmp = client.get url
      tmp['associatedUsers']['users'].pmap do |user_url|
        url = user_url
        user = client.get url
        client.create(GoodData::Profile, user)
      end
    end

    # Gets Raw object URI
    #
    # @return [string] URI of this project role
    def uri
      @json['projectRole']['links']['roleUsers'].split('/')[0...-1].join('/')
    end

    def ==(other)
      uri == other.uri
    end
  end
end
