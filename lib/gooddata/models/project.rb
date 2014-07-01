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
        GoodData.profile.projects
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

      # Takes one CSV line and creates hash from data extracted
      #
      # @param row CSV row
      def user_csv_import(row)
        {
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
      Time.parse(@json['project']['meta']['created'])
    end

    # Gets dashboard by title, link, id
    #
    # @param [String] name Name, ID or URL of dashboard
    # @return [GoodData::Dashboard] Dashboard instance if found
    def dashboard(name)
      dbs = dashboards
      dbs.each do |db|
        return db if db.title == name || db.uri == name
      end
      nil
    end

    # Gets project dashboards
    def dashboards
      url = "/gdc/md/#{obj_id}/query/projectdashboards"
      raw = GoodData.get url
      raw['query']['entries'].map do |entry|
        raw_dashboard = GoodData.get(entry['link'])
        Dashboard.new(raw_dashboard)
      end
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

    # Gets processes for the project
    #
    # @return [Array<GoodData::Process>] Processes for the current project
    def processes
      GoodData::Process.all
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

    # Gets project role by its identifier
    #
    # @param [String] role_name Title of role to look for
    # @return [GoodData::ProjectRole] Project role if found
    def get_role_by_identifier(role_name, role_list = roles)
      role_name = role_name.downcase.gsub(/role$/, '')
      role_list.each do |role|
        tmp_role_name = role.identifier.downcase.gsub(/role$/, '')
        return role if tmp_role_name == role_name
      end
      nil
    end

    # Gets project role byt its summary
    #
    # @param [String] role_summary Summary of role to look for
    # @return [GoodData::ProjectRole] Project role if found
    def get_role_by_summary(role_summary, role_list = roles)
      role_list.each do |role|
        return role if role.summary.downcase == role_summary.downcase
      end
      nil
    end

    # Gets project role by its name
    #
    # @param [String] role_title Title of role to look for
    # @return [GoodData::ProjectRole] Project role if found
    def get_role_by_title(role_title, role_list = roles)
      role_list.each do |role|
        return role if role.title.downcase == role_title.downcase
      end
      nil
    end

    # Gets project role
    #
    # @param [String] role_title Title of role to look for
    # @return [GoodData::ProjectRole] Project role if found
    def get_role(role_name, role_list = roles)
      return role_name if role_name.is_a? GoodData::ProjectRole

      role_name.downcase!
      role_list.each do |role|
        return role if role.uri == role_name ||
          role.identifier.downcase == role_name ||
          role.identifier.downcase.gsub(/role$/, '') == role_name ||
          role.title.downcase == role_name ||
          role.summary.downcase == role_name
      end
      nil
    end

    # Gets user by its email, full_name, login or uri
    #
    # @param [String] name Name to look for
    # @param [Array<GoodData::User>]user_list Optional cached list of users used for look-ups
    # @return [GoodDta::Membership] User
    def get_user(name, user_list = users)
      return name if name.instance_of?(GoodData::Membership)
      fail ArgumentError, 'Invalid argument type of name - should be string or GoodData::Membership' if !name.kind_of?(String)

      name.downcase!
      user_list.each do |user|
        return user if user.uri.downcase == name ||
          user.login.downcase == name ||
          user.email.downcase == name
      end
      nil
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
        tmp = get_role(role)
        role_url = tmp.uri if tmp
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

    # Gets metadata
    def md
      @md ||= Links.new GoodData.get(data['links']['metadata'])
    end

    # Gets membership for profile specified
    #
    # @param [GoodData::Profile] profile - Profile to be checked
    # @param [Array<GoodData::Membership>] list Optional list of members to check against
    # @return [GoodData::Membership] Membership if found
    def member(profile, list = members)
      if profile.is_a? String
        return list.find do |m|
          m.uri == profile || m.login == profile
        end
      end
      list.find { |m| m.login == profile.login }
    end

    # Checks if the profile is member of project
    #
    # @param [GoodData::Profile] profile - Profile to be checked
    # @param [Array<GoodData::Membership>] list Optional list of members to check against
    # @return [Boolean] true if is member else false
    def member?(profile, list = members)
      !member(profile, list).nil?
    end

    # Gets all metric for project
    def metrics
      GoodData::Metric[:all, :project => self, :full => true]
    end

    # Gets metric by identifier, link or title
    def metric(id)
      ms = GoodData::Metric[:all, :project => self, :full => false]
      met = ms.find { |m| m['title'] == id || m['link'] == id || m['identifier'] == id }
      GoodData::Metric[met['link'], :project => self]
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

    # Gets dashboard by title, link, id
    #
    # @param [String] name Name, ID or URL of dashboard
    # @return [GoodData::Dashboard] Dashboard instance if found
    def report(name)
      reps = reports
      reps.each do |report|
        return report if report.title == name || report.uri == name
      end
      nil
    end

    # Gets the project reports
    def reports
      url = "/gdc/md/#{obj_id}/query/reports"
      res = GoodData.get url
      res['query']['entries'].map do |entry|
        raw_report = GoodData.get(entry['link'])
        Report.new(raw_report)
      end
    end

    # Gets the list or project roles
    #
    # @return [Array<GoodData::ProjectRole>] List of roles
    def roles
      url = "/gdc/projects/#{pid}/roles"
      tmp = GoodData.get(url)
      tmp['projectRoles']['roles'].map do |role_url|
        json = GoodData.get role_url
        GoodData::ProjectRole.new(json)
      end
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
      Time.parse(@json['project']['meta']['updated'])
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
        res << GoodData::Membership.new(user)
      end

      res
    end

    alias_method :members, :users

    def users_create(list, role_list = roles)
      domains = {}
      list.map do |user|
        # TODO: Add user here
        domain_name = user.json['user']['content']['domain']

        # Lookup for domain in cache'
        domain = domains[domain_name]

        # Get domain info from REST, add to cache
        if domain.nil?
          domain = {
            :domain => GoodData::Domain[domain_name],
            :users => GoodData::Domain[domain_name].users
          }

          domain[:users_map] = Hash[domain[:users].map { |u| [u.email, u] }]
          domains[domain_name] = domain
        end

        # Check if user exists in domain
        domain_user = domain[:users_map][user.email]
        fail ArgumentError, "Trying to add user '#{user.login}' which is not valid user in domain '#{domain_name}'" if domain_user.nil?

        # Lookup for role
        role_name = user.json['user']['content']['role'] || 'readOnlyUser'
        role = get_role(role_name, role_list)
        fail ArgumentError, "Invalid role name specified '#{role_name}' for user '#{user.email}'" if role.nil?

        # Assign user project role
        set_user_roles(domain_user, [role.uri], role_list)
      end
    end

    # Imports users from CSV
    #
    # # Features
    # - Create new users
    # - Delete old users
    # - Update existing users
    #
    # CSV Format
    # TODO: Describe CSV Format here
    #
    # @param path CSV file to be loaded
    # @param opts Optional additional options
    def users_import(new_users, domain = nil)
      # Diff users
      diff = GoodData::Membership.diff_list(users, new_users)

      # Create domain users
      GoodData::Domain.users_create(diff[:added], domain)

      # Create new users
      role_list = roles
      users_create(diff[:added], role_list)

      # Get changed users objects from hash
      list = diff[:changed].map do |user|
        user[:user]
      end

      # Join list of changed users with 'same' users
      list = list.zip(diff[:same]).flatten.compact

      new_users_map = Hash[new_users.map { |u| [u.email, u] }]

      # Create list with user, desired_roles hashes
      list = list.map do |user|
        {
          :user => user,
          :roles => new_users_map[user.email].json['user']['content']['role'].split(' ').map { |r| r.downcase }.sort
        }
      end

      # Update existing users
      set_users_roles(list, role_list)

      # Remove old users
      users_remove(diff[:removed])
    end

    # Disable users
    #
    # @param list List of users to be disabled
    def users_remove(list)
      list.map do |user|
        user.disable
      end
    end

    # Update user
    #
    # @param user User to be updated
    # @param desired_roles Roles to be assigned to user
    # @param role_list Optional cached list of roles used for lookups
    def set_user_roles(user, desired_roles, role_list = roles)
      if user.is_a? String
        user = get_user(user)
        fail ArgumentError, "Invalid user '#{user}' specified" if user.nil?
      end

      desired_roles = [desired_roles] unless desired_roles.is_a? Array

      roles = desired_roles.map do |role_name|
        role = get_role(role_name, role_list)
        fail ArgumentError, "Invalid role '#{role_name}' specified for user '#{user.email}'" if role.nil?
        role.uri
      end

      url = "#{uri}/users"
      payload = {
        'user' => {
          'content' => {
            'status' => 'ENABLED',
            'userRoles' => roles
          },
          'links' => {
            'self' => user.uri
          }
        }
      }

      GoodData.post url, payload
    end

    alias_method :add_user, :set_user_roles

    # Update list of users
    #
    # @param list List of users to be updated
    # @param role_list Optional list of cached roles to prevent unnecessary server round-trips
    def set_users_roles(list, role_list = roles)
      list.map do |user_hash|
        user = user_hash[:user]
        roles = user_hash[:role] || user_hash[:roles]
        {
          :user => user,
          :result => set_user_roles(user, roles, role_list)
        }
      end
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
