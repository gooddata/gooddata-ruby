# encoding: UTF-8

require_relative '../rest/rest'

module GoodData
  class Invitation < GoodData::Rest::Object
    def initialize(json)
      @json = json
    end

    def contributor
      data = client.get @json['invitation']['meta']['contributor']
      client.create GoodData::AccountSettings, data
    end

    def created
      DateTime.parse(@json['invitation']['meta']['created'])
    end

    def email
      @json['invitation']['content']['email']
    end

    def first_name
      @json['invitation']['content']['firstname']
    end

    def phone
      @json['invitation']['content']['phone']
    end

    def profile
      data = client.get @json['invitation']['links']['profile']
      client.create GoodData::AccountSettings, data
    end

    def project
      data = client.get @json['invitation']['links']['project']
      client.create GoodData::Project, data
    end

    def project_name
      @json['invitation']['content']['projectname']
    end

    def role
      # TODO: Return object instead
      @json['invitation']['content']['role']
    end

    def status
      @json['invitation']['content']['status']
    end

    def summary
      @json['invitation']['content']['summary']
    end

    def title
      @json['invitation']['content']['title']
    end

    def updated
      DateTime.parse(@json['invitation']['meta']['updated'])
    end

    def uri
      @json['invitation']['links']['self']
    end
  end
end
