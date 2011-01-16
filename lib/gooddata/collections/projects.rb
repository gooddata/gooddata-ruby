module GoodData
  class Projects < Array
    def initialize(connection, projects)
      @connection = connection
      projects.each { |p| self.push p }
    end

    def find(*args)
      raise ArgumentError.new "wrong number of arguments (#{args.size} for 1)" if args.size != 1
      raise ArgumentError.new "wrong type of argument. Should be either project ID or path" if args[0].to_s !~ /^(\/gdc\/(projects|md)\/)?[a-z\d]+$/ 

      args[0] = args[0].match(/[a-z\d]+$/)[0] if args[0] =~ /\//

      response = @connection.get Project::PROJECT_PATH % args[0]
      Project.new @connection, response['project']
    end

    def create(attributes)
      GoodData.logger.info "Creating project #{attributes[:name]}"

      json = {
        'meta' => {
          'title' => attributes[:name],
          'summary' => attributes[:summary]
        },
        'content' => {
          # 'state' => 'ENABLED',
          'guidedNavigation' => 1
        }
      }

      json['meta']['projectTemplate'] = attributes[:template] if attributes.has_key? :template

      self << GoodData::Project.create(json)
      last
    end
  end
end
