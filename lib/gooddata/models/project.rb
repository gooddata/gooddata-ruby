# encoding: UTF-8

require 'csv'
require 'zip'
require 'fileutils'

require_relative 'process'
require_relative '../exceptions/no_project_error'
require_relative 'project_role'

module GoodData
  class Project
    USERSPROJECTS_PATH = '/gdc/account/profile/%s/projects'
    PROJECTS_PATH = '/gdc/projects'
    PROJECT_PATH = '/gdc/projects/%s'
    SLIS_PATH = '/ldm/singleloadinterface'
    DEFAULT_INVITE_MESSAGE = 'Join us!'

    attr_accessor :connection, :json

    class << self
      # Returns an array of all projects accessible by
      # current user
      def all
        json = GoodData.get GoodData.profile.projects
        json['projects'].map do |project|
          Project.new project
        end
      end

      # Returns a Project object identified by given string
      # The following identifiers are accepted
      #  - /gdc/md/<id>
      #  - /gdc/projects/<id>
      #  - <id>
      #
      def [](id, options = {})
        return id if id.respond_to?(:project?) && id.project?
        if id == :all
          Project.all
        else
          if id.to_s !~ %r{^(\/gdc\/(projects|md)\/)?[a-zA-Z\d]+$}
            fail(ArgumentError, 'wrong type of argument. Should be either project ID or path')
          end

          id = id.match(/[a-zA-Z\d]+$/)[0] if id =~ /\//

          response = GoodData.get PROJECT_PATH % id
          Project.new response
        end
      end

      # Create a project from a given attributes
      # Expected keys:
      # - :title (mandatory)
      # - :summary
      # - :template (default /projects/blank)
      #
      def create(attributes, &block)
        GoodData.logger.info "Creating project #{attributes[:title]}"

        auth_token = attributes[:auth_token] || GoodData.connection.auth_token
        fail 'You have to provide your token for creating projects as :auth_token parameter' if auth_token.nil? || auth_token.empty?

        json = {
          'project' =>
            {
              'meta' => {
                'title' => attributes[:title],
                'summary' => attributes[:summary] || 'No summary'
              },
              'content' => {
                'guidedNavigation' => attributes[:guided_navigation] || 1,
                'authorizationToken' => auth_token,
                'driver' => attributes[:driver] || 'Pg'
              }
            }
        }

        json['project']['meta']['projectTemplate'] = attributes[:template] if attributes[:template] && !attributes[:template].empty?
        project = Project.new json
        project.save

        # until it is enabled or deleted, recur. This should still end if there is a exception thrown out from RESTClient. This sometimes happens from WebApp when request is too long
        while project.state.to_s != 'enabled'
          if project.state.to_s == 'deleted'
            # if project is switched to deleted state, fail. This is usually problem of creating a template which is invalid.
            fail 'Project was marked as deleted during creation. This usually means you were trying to create from template and it failed.'
          end
          sleep(3)
          project.reload!
        end

        if block
          GoodData.with_project(project) do |p|
            block.call(p)
          end
        end
        sleep 3
        project
      end
    end

    # Creates a data set within the project
    #
    # == Usage
    # p.add_dataset 'Test', [ { 'name' => 'a1', 'type' => 'ATTRIBUTE' ... } ... ]
    # p.add_dataset 'title' => 'Test', 'columns' => [ { 'name' => 'a1', 'type' => 'ATTRIBUTE' ... } ... ]
    #
    def add_dataset(schema_def, columns = nil, &block)
      schema = if block
                 builder = block.call(Model::SchemaBuilder.new(schema_def))
                 builder.to_schema
               else
                 sch = { :title => schema_def, :columns => columns } if columns
                 sch = Model::Schema.new schema_def if schema_def.is_a? Hash
                 sch = schema_def if schema_def.is_a?(Model::Schema)
                 fail(ArgumentError, 'Required either schema object or title plus columns array') unless schema_def.is_a? Model::Schema
                 sch
               end
      Model.add_schema(schema, self)
    end

    def add_metric(options = {})
      options[:expression] || fail('Metric has to have its expression defined')
      m1 = GoodData::Metric.create(options)
      m1.save
    end

    def add_report(options = {})
      rep = GoodData::Report.create(options)
      rep.save
    end

    # Gets author of project
    #
    # @return [String] Project author
    def author
      # TODO: Return object instead
      @json['project']['meta']['author']
    end

    # Adds user to project
    #
    # TODO: Discuss with @fluke777 if is not #invite sufficient
    def add_user(email_address, domain)
      fail 'Not implemented'
    end

    # Returns web interface URI of project
    #
    # @return [String] Project URL
    def browser_uri(options = {})
      grey = options[:grey]
      if grey
        GoodData.connection.url + uri
      else
        GoodData.connection.url + '#s=' + uri
      end
    end

    # Clones project
    #
    # @return [GoodData::Project] Newly created project
    def clone(options = {})
      # TODO: Refactor so if export or import fails the new_project will be cleaned
      with_data = options[:data] || true
      with_users = options[:users] || false
      title = options[:title] || "Clone of #{title}"

      # Create the project first so we know that it is passing. What most likely is wrong is the tokena and the export actaully takes majoiryt of the time
      new_project = GoodData::Project.create(options.merge(:title => title))

      export = {
        :exportProject => {
          :exportUsers => with_users ? 1 : 0,
          :exportData => with_data ? 1 : 0
        }
      }

      result = GoodData.post("/gdc/md/#{obj_id}/maintenance/export", export)
      export_token = result['exportArtifact']['token']
      status_url = result['exportArtifact']['status']['uri']

      state = GoodData.get(status_url)['taskState']['status']
      while state == 'RUNNING'
        sleep 5
        result = GoodData.get(status_url)
        state = result['taskState']['status']
      end

      import = {
        :importProject => {
          :token => export_token
        }
      }

      result = GoodData.post("/gdc/md/#{new_project.obj_id}/maintenance/import", import)
      status_url = result['uri']
      state = GoodData.get(status_url)['taskState']['status']
      while state == 'RUNNING'
        sleep 5
        result = GoodData.get(status_url)
        state = result['taskState']['status']
      end
      new_project
    end

    # Project contributor
    #
    # @return [String] Project contributor
    # TODO: Return as object
    def contributor
      # TODO: Return object instead
      @json['project']['meta']['contributor']
    end

    # Gets the date when created
    #
    # @return [DateTime] Date time when created
    def created
      DateTime.parse(@json['project']['meta']['created'])
    end

    # Gets ruby wrapped raw project JSON data
    def data
      raw_data['project']
    end

    def datasets
      datasets_uri = "#{md['data']}/sets"
      response = GoodData.get datasets_uri
      response['dataSetsInfo']['sets'].map do |ds|
        DataSet[ds['meta']['uri']]
      end
    end

    # Deletes project
    def delete
      fail "Project '#{title}' with id #{uri} is already deleted" if state == :deleted
      GoodData.delete(uri)
    end

    # Deletes dashboards for project
    def delete_dashboards
      Dashboard.all.map { |data| Dashboard[data['link']] }.each { |d| d.delete }
    end

    # Exports project users to file
    def export_users(path)
      header = %w(email login first_name last_name status)
      GoodData::Helpers.csv_write(:path => path, :header => header, :data => users) do |user|
        [user.email, user.login, user.first_name, user.last_name, user.status]
      end
    end

    # Gets project role by its identifier
    #
    # @param [String] role_name Title of role to look for
    # @return [GoodData::ProjectRole] Project role if found
    def get_role_by_identifier(role_name)
      tmp = roles
      tmp.each do |role|
        return role if role.identifier.downcase == role_name.downcase
      end
      nil
    end

    # Gets project role byt its summary
    #
    # @param [String] role_summary Summary of role to look for
    # @return [GoodData::ProjectRole] Project role if found
    def get_role_by_summary(role_summary)
      tmp = roles
      tmp.each do |role|
        return role if role.summary.downcase == role_summary.downcase
      end
      nil
    end

    # Gets project role by its name
    #
    # @param [String] role_title Title of role to look for
    # @return [GoodData::ProjectRole] Project role if found
    def get_role_by_title(role_title)
      tmp = roles
      tmp.each do |role|
        return role if role.title.downcase == role_title.downcase
      end
      nil
    end

    # Exports project users to file
    def import_users(path, opts = { :header => true }, &block)
      opts[:path] = path

      new_users = GoodData::Helpers.csv_read(opts) do |row|
        json = {}
        if block_given?
          json = yield row
        else
          json = {
            'user' => {
              'content' => {
                'email' => row[0],
                'login' => row[1],
                'firstname' => row[2],
                'lastname' => row[3]
              },
              'meta' => {}
            }
          }
        end

        GoodData::User.new(json)
      end

      current_users = users
      diff = GoodData::User.diff_list(current_users, new_users)

      domains = {}

      diff[:added].each do |user|
        # TODO: Add user here
        domain_name = user.json['user']['content']['domain']
        domains[domain_name] = GoodData::Domain[domain_name] unless domains[domain_name]
        domain = domains[domain_name]

        domain_users = domain.users
        user_index = domain_users.index { |u| u.email == user.email }

        if user_index.nil?
          password = user.json['user']['content']['password']

          # TODO: Create user here
          user_data = {
            :login => user.login,
            :firstName => user.first_name,
            :lastName => user.last_name,
            :password => password,
            :verifyPassword => password,
            :email => user.login
          }

          domain.add_user(user_data)
          domain_users = domain.users
          # user_index = domain_users.index { |u| u.email == user.email }
        end

        # TODO: Setup role here
      end

      diff[:removed].each do |user|
        user.disable(self)
      end
    end

    # Initializes object instance from raw wire JSON
    #
    # @param json Json used for initialization
    def initialize(json)
      @json = json
    end

    # Invites new user to project
    #
    # @param email [String] User to be invited
    # @param role [String] Role URL or Role ID to be used
    # @param msg [String] Optional invite message
    #
    # TODO: Return invite object
    def invite(email, role, msg = DEFAULT_INVITE_MESSAGE)
      puts "Inviting #{email}, role: #{role}"

      role_url = nil
      if role.index('/gdc/') != 0
        tmp = get_role_by_identifier(role)
        tmp = get_role_by_title(role) if tmp.nil?
        role_url = tmp['url'] if tmp
      else
        role_url = role if role_url.nil?
      end

      data = {
        :invitations => [
          {
            :invitation => {
              :content => {
                :email => email,
                :role => role_url,
                :action => {
                  :setMessage => msg
                }
              }
            }
          }
        ]
      }

      url = "/gdc/projects/#{pid}/invitations"
      GoodData.post(url, data)
    end

    # Returns invitations to project
    #
    # @return [Array<GoodData::Invitation>] List of invitations
    def invitations
      res = []

      tmp = GoodData.get @json['project']['links']['invitations']
      tmp['invitations'].each do |invitation|
        res << GoodData::Invitation.new(invitation)
      end

      res
    end

    # Returns project related links
    #
    # @return [Hash] Project related links
    def links
      data['links']
    end

    def md
      @md ||= Links.new GoodData.get(data['links']['metadata'])
    end

    # Gets raw resource ID
    #
    # @return [String] Raw resource ID
    def obj_id
      uri.split('/').last
    end

    alias_method :pid, :obj_id

    def partial_md_export(objects, options = {})
      # TODO: refactor polling to md_polling in client

      fail 'Nothing to migrate. You have to pass list of objects, ids or uris that you would like to migrate' if objects.nil? || objects.empty?
      fail 'The objects to migrate has to be provided as an array' unless objects.is_a?(Array)

      target_project = options[:project]
      fail 'You have to provide a project instance or project pid to migrate to' if target_project.nil?
      target_project = GoodData::Project[target_project]
      objects = objects.map { |obj| GoodData::MdObject[obj] }
      export_payload = {
        :partialMDExport => {
          :uris => objects.map { |obj| obj.uri }
        }
      }
      result = GoodData.post("#{GoodData.project.md['maintenance']}/partialmdexport", export_payload)
      polling_url = result['partialMDArtifact']['status']['uri']
      token = result['partialMDArtifact']['token']

      polling_result = GoodData.wait_for_polling_result(polling_url)

      fail 'Exporting objects failed' if polling_result['wTaskStatus']['status'] == 'ERROR'

      import_payload = {
        :partialMDImport => {
          :token => token,
          :overwriteNewer => '1',
          :updateLDMObjects => '0'
        }
      }

      result = GoodData.post("#{target_project.md['maintenance']}/partialmdimport", import_payload)
      polling_url = result['uri']
      polling_result = GoodData.wait_for_polling_result(polling_url)

      fail 'Exporting objects failed' if polling_result['wTaskStatus']['status'] == 'ERROR'
    end

    alias_method :transfer_objects, :partial_md_export

    # Checks if this object instance is project
    #
    # @return [Boolean] Return true for all instances
    def project?
      true
    end

    # Forces project to reload
    def reload!
      if saved?
        response = GoodData.get(uri)
        @json = response
      end
      self
    end

    # Gets the list or project roles
    #
    # @return [Array<GoodData::ProjectRole>] List of roles
    def roles
      url = "/gdc/projects/#{pid}/roles"

      res = []

      tmp = GoodData.get(url)
      tmp['projectRoles']['roles'].each do |role_url|
        json = GoodData.get role_url
        res << GoodData::ProjectRole.new(json)
      end

      res
    end

    # Saves project
    def save
      response = GoodData.post PROJECTS_PATH, raw_data
      if uri.nil?
        response = GoodData.get response['uri']
        @json = response
      end
    end

    # Checks if is project saved
    #
    # @return [Boolean] True if saved, false if not
    def saved?
      res = uri.nil?
      !res
    end

    # Gets project schedules
    #
    # @return [Array<GoodData::Schedule>] List of schedules
    def schedules
      res = []
      tmp = GoodData.get @json['project']['links']['schedules']
      tmp['schedules']['items'].each do |schedule|
        res << GoodData::Schedule.new(schedule)
      end
      res
    end

    # Gets SLIs data
    #
    # @return [GoodData::Metadata] SLI Metadata
    def slis
      link = "#{data['links']['metadata']}#{SLIS_PATH}"

      # TODO: Review what to do with passed extra argument
      Metadata.new GoodData.get(link)
    end

    # Gets project state
    #
    # @return [String] Project state
    def state
      data['content']['state'].downcase.to_sym if data['content'] && data['content']['state']
    end

    # Gets project summary
    #
    # @return [String] Project summary
    def summary
      data['meta']['summary'] if data['meta']
    end

    # Gets project title
    #
    # @return [String] Project title
    def title
      data['meta']['title'] if data['meta']
    end

    # Gets project update date
    #
    # @return [DateTime] Date time of last update
    def updated
      DateTime.parse(@json['project']['meta']['updated'])
    end

    # Uploads file to project
    #
    # @param file File to be uploaded
    # @param schema Schema to be used
    def upload(file, schema, mode = 'FULL')
      schema.upload file, self, mode
    end

    def uri
      data['links']['self'] if data && data['links'] && data['links']['self']
    end

    # List of users in project
    #
    # @return [Array<GoodData::User>] List of users
    def users
      res = []

      tmp = GoodData.get @json['project']['links']['users']
      tmp['users'].map do |user|
        res << GoodData::User.new(user)
      end

      res
    end

    # Run validation on project
    # Valid settins for validation are (default all):
    # ldm - Checks the consistency of LDM objects.
    # pdm Checks LDM to PDM mapping consistency, also checks PDM reference integrity.
    # metric_filter - Checks metadata for inconsistent metric filters.
    # invalid_objects - Checks metadata for invalid/corrupted objects.
    # asyncTask response
    def validate(filters = %w(ldm, pdm, metric_filter, invalid_objects))
      response = GoodData.post "#{GoodData.project.md['validate-project']}", 'validateProject' => filters
      polling_link = response['asyncTask']['link']['poll']
      polling_result = GoodData.get(polling_link)
      while polling_result['wTaskStatus'] && polling_result['wTaskStatus']['status'] == 'RUNNING'
        sleep(3)
        polling_result = GoodData.get(polling_link)
      end
      polling_result
    end

    alias_method :to_json, :json
    alias_method :raw_data, :json
  end
end
