# encoding: UTF-8

module GoodData
  class Invitation
    def initialize(json)
      @json = json
    end

    def author
      # TODO: Return object instead
      @json['invitation']['meta']['author']
    end

    def contributor
      # TODO: Return object instead
      @json['invitation']['meta']['contributor']
    end

    def created
      Time.parse(@json['invitation']['meta']['created'])
    end

    def email
      @json['invitation']['content']['email']
    end

    def first_name
      @json['invitation']['content']['firstname']
    end

    def first_name
      @json['invitation']['content']['firstname']
    end

    def phone
      @json['invitation']['content']['phone']
    end

    def profile
      # TODO: Return object instead
      @json['invitation']['links']['profile']
    end

    def project
      # TODO: Return object instead
      @json['invitation']['links']['project']
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
      Time.parse(@json['invitation']['meta']['updated'])
    end

    def uri
      @json['invitation']['links']['self']
    end
  end
end
