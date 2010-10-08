module Gooddata
  class Project
    PROJECTS_PATH = '/gdc/projects'
    PROJECT_PATH = '/gdc/projects/%i'

    class << self
      def find(*args)
        raise ArgumentError.new "wrong number of arguments (#{args.size} for 1)" if args.size != 1
        raise ArgumentError.new "wrong type of argument. Should be either project ID or path" if args[0].to_s !~ /^(\/gdc\/projects\/)?\d+$/ 

        args[0] = args[0].match(/\d+$/)[0] if args[0] =~ /\//

        response = Connection.instance.get PROJECT_PATH % args[0]
        Project.new response['project']
      end

      def create(json)
        project = Project.new json
        project.save
        project
      end
    end

    def initialize(json)
      @json = json
    end

    def save
      response = Connection.instance.post PROJECTS_PATH, { 'project' => @json }
      if id == nil
        response = Connection.instance.get response['uri']
        @json = response['project']
      end
    end

    def delete
      raise "Project '#{name}' with id #{id} is already deleted" if state == :deleted
      Connection.instance.delete @json['links']['self']
    end

    def id
      @json['links']['self'].match(/\d+$/)[0] if @json['links'] && @json['links']['self']
    end

    def name
      @json['meta']['title'] if @json['meta']
    end

    def state
      @json['content']['state'].downcase.to_sym if @json['content'] && @json['content']['state']
    end

    def to_json
      @json
    end
  end
end