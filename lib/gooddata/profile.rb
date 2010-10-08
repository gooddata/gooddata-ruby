module Gooddata
  class Profile
    private_class_method :new
    attr_reader :user

    class << self
      def load
        Gooddata.logger.info "Loading user profile..."
        Profile.send 'new'
      end
    end

    def projects
      unless @projects
        json = Connection.instance.get(@projects_path)['projects']
        projects_array = json.map do |project|
          Project.new project['project']
        end
        @projects = Collections::Projects.new projects_array
      end
      @projects
    end

    def to_json
      @json
    end

    private

    def initialize
      @json = Connection.instance.get Connection.instance.user['profile']
      @user = @json['accountSetting']['firstName'] + " " + @json['accountSetting']['lastName']
      @projects_path = @json['accountSetting']['links']['projects']
    end
  end
end