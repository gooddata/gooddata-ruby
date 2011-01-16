module GoodData
  class Profile
    private_class_method :new
    attr_reader :user

    class << self
      def load(connection)
        GoodData.logger.info "Loading user profile..."
        Profile.send 'new', connection
      end
    end

    def projects
      unless @projects
        json = @connection.get(@projects_path)['projects']
        projects_array = json.map do |project|
          Project.new @connection, project['project']
        end
        @projects = Projects.new @connection, projects_array
      end
      @projects
    end

    def to_json
      @json
    end

    private

    def initialize(connection)
      @connection = connection
      @json = @connection.get @connection.user['profile']
      @user = @json['accountSetting']['firstName'] + " " + @json['accountSetting']['lastName']
      @projects_path = @json['accountSetting']['links']['projects']
    end
  end
end