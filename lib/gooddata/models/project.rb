module GoodData
  class Project
    USERSPROJECTS_PATH = '/gdc/account/profile/%s/projects'
    PROJECTS_PATH = '/gdc/projects'
    PROJECT_PATH = '/gdc/projects/%s'
    SLIS_PATH = '/ldm/singleloadinterface'

    attr_accessor :connection

    class << self
      def load
        # GoodData.logger.info "Loading user profile..."
        Profile.send 'new'
      end

      # Returns an array of all projects accessible by
      # current user
      def all
        json = GoodData.get GoodData.profile.projects
        json['projects'].map do |project|
          Project.new project['project']
        end
      end

      # Returns a Project object identified by given string
      # The following identifiers are accepted
      #  - /gdc/md/<id>
      #  - /gdc/projects/<id>
      #  - <id>
      #
      def [](id)
        if id.to_s !~ /^(\/gdc\/(projects|md)\/)?[a-zA-Z\d]+$/
          raise ArgumentError.new "wrong type of argument. Should be either project ID or path"
        end

        id = id.match(/[a-zA-Z\d]+$/)[0] if id =~ /\//

        response = GoodData.get PROJECT_PATH % id
        Project.new response['project']
      end

      # Create a project from a given attributes
      # Expected keys:
      # - :title (mandatory)
      # - :summary
      # - :template (default /projects/blank)
      #
      def create(attributes)
        GoodData.logger.info "Creating project #{attributes[:title]}"

        json = {
          'meta' => {
            'title' => attributes[:title],
            'summary' => attributes[:summary]
          },
          'content' => {
            # 'state' => 'ENABLED',
            'guidedNavigation' => 1
          }
        }

        project = GoodData::Project.new json
        project.save
        project
      end
    end

    def initialize(json)
      @json = json
    end

    def save
      response = GoodData.post PROJECTS_PATH, { 'project' => @json }
      if uri == nil
        response = GoodData.get response['uri']
        @json = response['project']
      end
    end

    def delete
      raise "Project '#{title}' with id #{uri} is already deleted" if state == :deleted
      GoodData.delete @json['links']['self']
    end

    def uri
      @json['links']['self'] if @json['links'] && @json['links']['self']
    end

    def title
      @json['meta']['title'] if @json['meta']
    end

    def state
      @json['content']['state'].downcase.to_sym if @json['content'] && @json['content']['state']
    end

    def md
      unless @md
        @md = Metadata.new GoodData.get @json['links']['metadata']
      end
      @md
    end

    def slis
      link = "#{@json['links']['metadata']}#{SLIS_PATH}"
      Metadata.new GoodData.get link
    end

    def datasets
      datasets_uri  = "#{md['data']}/sets"
      response      = GoodData.get datasets_uri
      response['dataSetsInfo']['sets'].map do |ds|
        ds # TODO wrap with an instance of the Dataset object once implemented
      end
    end

    def to_json
      @json
    end
  end
end