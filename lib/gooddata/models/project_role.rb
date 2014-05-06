# encoding: UTF-8

module GoodData
  class ProjectRole
    def initialize(json)
      @json = json
    end

    def identifier
      @json['projectRole']['meta']['identifier']
    end

    def author
      @json['projectRole']['meta']['author']
    end

    def contributor
      @json['projectRole']['meta']['contributor']
    end

    def created
      Time.parse(@json['projectRole']['meta']['created'])
    end

    def permissions
      @json['projectRole']['permissions']
    end

    def title
      @json['projectRole']['meta']['title']
    end

    def summary
      @json['projectRole']['meta']['summary']
    end

    def updated
      Time.parse(@json['projectRole']['meta']['updated'])
    end
  end
end
