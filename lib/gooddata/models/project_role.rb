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

    EMPTY_OBJECT = {
      'projectRole' => {
        'permissions' => {},
        'links' => {},
        'meta' => {}
      }
    }

    def self.create_object(data)
      meta_data = {}.tap do |d|
        d[:created] = data[:created] || Time.now
        d[:identifier] = data[:identifier]
        d[:updated] = data[:updated] || d[:created] || Time.now
        d[:title] = data[:title]
        d[:summary] = data[:summary]
      end
      new_data = EMPTY_OBJECT.deep_dup.tap do |d|
        d['projectRole']['links']['self'] = data[:uri] if data[:uri]
        d['projectRole']['meta'] = d['projectRole']['meta'].merge(meta_data.stringify_keys)
        d['projectRole']['permissions'] = d['projectRole']['permissions'].merge((data[:permissions] || {}).stringify_keys)
      end
      new(new_data)
    end

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
      return @json['projectRole']['links']['self'] if @json['projectRole']['links']['self']
      return nil unless @json['projectRole']['links']['roleUsers']
      @json['projectRole']['links']['roleUsers'].split('/')[0...-1].join('/')
    end

    def ==(other)
      uri == other.uri
    end
  end
end
