module GoodData
  class Projects < Array
    def initialize(connection, projects)
      @connection = connection
      projects.each { |p| self.push p }
    end

    def find(id)
      if id.to_s !~ /^(\/gdc\/(projects|md)\/)?[a-z\d]+$/
        raise ArgumentError.new "wrong type of argument. Should be either project ID or path"
      end

      id = id.match(/[a-z\d]+$/)[0] if id =~ /\//

      response = @connection.get Project::PROJECT_PATH % id
      Project.new @connection, response['project']
    end

    ##
    # If id is a string, acts as Array[] (i.e. "i" is treated as an array index),
    # otherwise returns the project identified by the id identifier (i.e. acts as
    # an alias of the find method)
    #
    def [](id)
      if id.respond_to? :integer?
        super
      else
        find(id)
      end
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

      project = GoodData::Project.new @connection, json
      project.save
      self << project
      project
    end
  end
end
