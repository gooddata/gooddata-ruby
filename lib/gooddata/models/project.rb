# encoding: UTF-8

require 'csv'
require 'zip'
require 'fileutils'
require 'pmap'
require 'zip'

require_relative '../exceptions/no_project_error'

require_relative '../mixins/rest_resource'
require_relative '../rest/resource'

require_relative 'process'
require_relative 'project_role'

module GoodData
  class Project < GoodData::Rest::Resource
    USERSPROJECTS_PATH = '/gdc/account/profile/%s/projects'
    PROJECTS_PATH = '/gdc/projects'
    PROJECT_PATH = '/gdc/projects/%s'
    SLIS_PATH = '/ldm/singleloadinterface'
    DEFAULT_INVITE_MESSAGE = 'Join us!'

    attr_accessor :connection, :json

    alias_method :to_json, :json
    alias_method :raw_data, :json

    include GoodData::Mixin::RestResource

    Project.root_key :project

    include GoodData::Mixin::Author
    include GoodData::Mixin::Contributor

    class << self
      # Returns an array of all projects accessible by
      # current user
      def all(opts = {})
        c = client(opts)
        c.user.projects
      end

      # Returns a Project object identified by given string
      # The following identifiers are accepted
      #  - /gdc/md/<id>
      #  - /gdc/projects/<id>
      #  - <id>
      #
      def [](id, opts = {})
        return id if id.instance_of? GoodData::Project || id.respond_to?(:project?) && id.project?

        if id == :all
          Project.all(opts)
        else
          if id.to_s !~ %r{^(\/gdc\/(projects|md)\/)?[a-zA-Z\d]+$}
            fail(ArgumentError, 'wrong type of argument. Should be either project ID or path')
          end

          id = id.match(/[a-zA-Z\d]+$/)[0] if id =~ /\//

          c = client(opts)
          response = c.get PROJECT_PATH % id
          c.factory.create(Project, response)
        end
      end

      # Create a project from a given attributes
      # Expected keys:
      # - :title (mandatory)
      # - :summary
      # - :template (default /projects/blank)
      #
      def create(opts = {:client => GoodData.connection}, &block)
        GoodData.logger.info "Creating project #{opts[:title]}"

        c = client(opts)
        fail ArgumentError, "No :client specified" if c.nil?

        auth_token = opts[:auth_token] || GoodData.connection.auth_token
        fail 'You have to provide your token for creating projects as :auth_token parameter' if auth_token.nil? || auth_token.empty?

        json = {
          'project' =>
            {
              'meta' => {
                'title' => opts[:title],
                'summary' => opts[:summary] || 'No summary'
              },
              'content' => {
                'guidedNavigation' => opts[:guided_navigation] || 1,
                'authorizationToken' => auth_token,
                'driver' => opts[:driver] || 'Pg'
              }
            }
        }

        json['project']['meta']['projectTemplate'] = opts[:template] if opts[:template] && !opts[:template].empty?
        project = c.create(Project, json)
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

      def find(opts = {}, client = GoodData::Rest::Client.client)
        user = client.user
        user.projects['projects'].map do |project|
          client.create(GoodData::Project, project)
        end
      end

      def create_from_blueprint(blueprint, options = {})
        GoodData::Model::ProjectCreator.migrate(:spec => blueprint, :token => options[:auth_token])
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

    def add_metric(options = {})
      options[:expression] || fail('Metric has to have its expression defined')
      m1 = GoodData::Metric.xcreate(options)
      m1.save
    end
    alias_method :create_metric, :add_metric

    def add_report(options = {})
      rep = GoodData::Report.create(options)
      rep.save
    end
    alias_method :create_report, :add_report

    # Returns an indication whether current user is admin in this project
    #
    # @return [Boolean] True if user has admin role in the project, false otherwise.
    def am_i_admin?
      user_has_role?(GoodData.user, 'admin')
    end

    # Helper for getting attributes of a project
    #
    # @param [String | Number | Object] Anything that you can pass to GoodData::Attribute[id]
    # @return [GoodData::Attribute | Array<GoodData::Attribute>] fact instance or list
    def attributes(id = :all)
      GoodData::Attribute[id, project: self]
    end

    # Gets project blueprint from the server
    #
    # @return [GoodData::ProjectRole] Project role if found
    def blueprint
      result = client.get("/gdc/projects/#{pid}/model/view")
      polling_url = result['asyncTask']['link']['poll']
      model = client.poll_on_code(polling_url)
      GoodData::Model::FromWire.from_wire(model)
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
      a_title = options[:title] || "Clone of #{title}"

      # Create the project first so we know that it is passing. What most likely is wrong is the tokena and the export actaully takes majoiryt of the time
      new_project = GoodData::Project.create(options.merge(:title => a_title, :client => client))

      export = {
        :exportProject => {
          :exportUsers => with_users ? 1 : 0,
          :exportData => with_data ? 1 : 0
        }
      }

      result = client.post("/gdc/md/#{obj_id}/maintenance/export", export)
      export_token = result['exportArtifact']['token']

      status_url = result['exportArtifact']['status']['uri']
      client.poll_on_response(status_url) do |body|
        body['taskState']['status'] == 'RUNNING'
      end

      import = {
        :importProject => {
          :token => export_token
        }
      }

      result = client.post("/gdc/md/#{new_project.obj_id}/maintenance/import", import)
      status_url = result['uri']
      client.poll_on_response(status_url) do |body|
        body['taskState']['status'] == 'RUNNING'
      end

      new_project
    end

    # Helper for getting dashboards of a project
    #
    # @param [String | Number | Object] Anything that you can pass to GoodData::Dashboard[id]
    # @return [GoodData::Dashboard | Array<GoodData::Dashboard>] dashboard instance or list
    def dashboards(id = :all)
      GoodData::Dashboard[:all, project: self, client: client]
    end

    def datasets
      blueprint.datasets
    end

    # Deletes project
    def delete
      fail "Project '#{title}' with id #{uri} is already deleted" if state == :deleted
      client.delete(uri)
    end

    # Deletes dashboards for project
    def delete_dashboards
      Dashboard.all.map { |data| Dashboard[data['link']] }.each { |d| d.delete }
    end

    # Executes DML expression. See (https://developer.gooddata.com/article/deleting-records-from-datasets)
    # for some examples and explanations
    #
    # @param dml [String] DML expression
    def execute_dml(dml)
      uri = "/gdc/md/#{pid}/dml/manage"
      result = GoodData.post(uri,
                             manage: {
                               maql: dml
                             })
      polling_uri = result['uri']
      result = client.get(polling_uri)
      while result['taskState'] && result['taskState']['status'] == 'WAIT'
        sleep 10
        result = client.get polling_uri
      end
    end

    # Helper for getting facts of a project
    #
    # @param [String | Number | Object] Anything that you can pass to GoodData::Fact[id]
    # @return [GoodData::Fact | Array<GoodData::Fact>] fact instance or list
    def facts(id)
      GoodData::Fact[id, project: self]
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
        a = role
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
      return member(name) if name.instance_of?(GoodData::Profile)
      name.downcase!
      user_list.each do |user|
        return user if user.uri.downcase == name ||
          user.login.downcase == name ||
          user.email.downcase == name
      end
      nil
    end

    # Exports project users to file
    def import_users(path, opts = { :header => true }, &block)
      opts[:path] = path

      ##########################
      # Caching/Cached objects
      ##########################
      domains = {}
      current_users = users
      role_list = roles

      ##########################
      # Load users from CSV
      ##########################
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

      ##########################
      # Diff users
      ##########################
      diff = GoodData::User.diff_list(current_users, new_users)

      ##########################
      # Create new users
      ##########################
      diff[:added].map do |user|
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

        # Create domain user if needed
        unless domain_user
          password = user.json['user']['content']['password']

          # Fill necessary user data
          user_data = {
            :login => user.login,
            :firstName => user.first_name,
            :lastName => user.last_name,
            :password => password,
            :verifyPassword => password,
            :email => user.login
          }

          # Add created user to cache
          domain_user = domain[:domain].add_user(user_data)
          domain[:users] << domain_user
          domain[:users_map][user.email] = domain_user
        end

        # Lookup for role
        role_name = user.json['user']['content']['role'] || 'readOnlyUser'
        role = get_role_by_identifier(role_name, role_list)
        next if role.nil?

        # Assign user project role
        add_user(domain_user, [role.uri])
      end

      ##########################
      # Remove old users
      ##########################
      # diff[:removed].map do |user|
      #   user.disable(self)
      # end
    end

    # Checks whether user has particular role in given proejct
    #
    # @param user [GoodData::Profile | GoodData::Membership | String] User in question. Can be passed by login (String), profile or membershi objects
    # @param role_name [String || GoodData::ProjectRole] Project role cna be given by either string or GoodData::ProjectRole object
    # @return [Boolean] Tru if user has role_name
    def user_has_role?(user, role_name)
      member = get_user(user)
      role = get_role(role_name)
      member.roles.include?(role)
    rescue
      false
    end

    # Initializes object instance from raw wire JSON
    #
    # @param json Json used for initialization
    def initialize(json)
      super
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
      invitations = client.get @json['project']['links']['invitations']
      invitations['invitations'].pmap do |invitation|
        client.create GoodData::Invitation, invitation
      end
    end

    # Returns project related links
    #
    # @return [Hash] Project related links
    def links
      data['links']
    end

    # Helper for getting labels of a project
    #
    # @param [String | Number | Object] Anything that you can pass to
    # GoodData::Label[id] + it supports :all as welll
    # @return [GoodData::Fact | Array<GoodData::Fact>] fact instance or list
    def labels(id = :all)
      attribute.pmapcat {|a| a.labels}
    end

    def md
      @md ||= client.create(Links, client.get(data['links']['metadata']))
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

    # Helper for getting metrics of a project
    #
    # @param [String | Number | Object] Anything that you can pass to GoodData::Metric[id]
    # @return [GoodData::Metric | Array<GoodData::Metric>] matric instance or list
    def metrics(id = :all)
      GoodData::Metric[id, project: self]
    end

    # Checks if the profile is member of project
    #
    # @param [GoodData::Profile] profile - Profile to be checked
    # @param [Array<GoodData::Membership>] list Optional list of members to check against
    # @return [Boolean] true if is member else false
    def member?(profile, list = members)
      !member(profile, list).nil?
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

      polling_result = GoodData.poll_on_response(polling_url) do |body|
        body['wTaskStatus'] && body['wTaskStatus']['status'] == 'RUNNING'
      end

      fail 'Exporting objects failed' if polling_result['wTaskStatus'] && polling_result['wTaskStatus']['status'] == 'ERROR'

      import_payload = {
        :partialMDImport => {
          :token => token,
          :overwriteNewer => '1',
          :updateLDMObjects => '0'
        }
      }

      result = GoodData.post("#{target_project.md['maintenance']}/partialmdimport", import_payload)
      polling_url = result['uri']

      GoodData.poll_on_response(polling_url) do |body|
        body['wTaskStatus'] && body['wTaskStatus']['status'] == 'RUNNING'
      end

      fail 'Exporting objects failed' if polling_result['wTaskStatus']['status'] == 'ERROR'
    end

    alias_method :transfer_objects, :partial_md_export

    # Helper for getting reports of a project
    #
    # @param [String | Number | Object] Anything that you can pass to GoodData::Report[id]
    # @return [GoodData::Report | Array<GoodData::Report>] report instance or list
    def processes(id = :all)
      GoodData::Process[id, project: self, client: client]
    end

    # Checks if this object instance is project
    #
    # @return [Boolean] Return true for all instances
    def project?
      true
    end

    def info
      results = blueprint.datasets.pmap do |ds|
        [ds, ds.count]
      end
      puts title
      puts GoodData::Helpers.underline(title)
      puts
      puts "Datasets - #{results.count}"
      puts
      results.each do |x|
        dataset, count = x
        dataset.title.tap do |t|
          puts t
          puts GoodData::Helpers.underline(t)
          puts "Size - #{count} rows"
          puts "#{dataset.attributes_and_anchors.count} attributes, #{dataset.facts.count} facts, #{dataset.references.count} references"
          puts
        end
      end
      nil
    end

    # Forces project to reload
    def reload!
      if saved?
        response = client.get(uri)
        @json = response
      end
      self
    end

    # Helper for getting reports of a project
    #
    # @param [String | Number | Object] Anything that you can pass to GoodData::Report[id]
    # @return [GoodData::Report | Array<GoodData::Report>] report instance or list
    def reports(id = :all)
      GoodData::Report[id, project: self]
    end

    # Helper for getting report definitions of a project
    #
    # @param [String | Number | Object] Anything that you can pass to GoodData::ReportDefinition[id]
    # @return [GoodData::ReportDefinition | Array<GoodData::ReportDefinition>] report definition instance or list
    def report_definitions(id = :all)
      GoodData::ReportDefinition[id, project: self, client: client]
    end

    # Gets the list or project roles
    #
    # @return [Array<GoodData::ProjectRole>] List of roles
    def roles()
      url = "/gdc/projects/#{pid}/roles"

      tmp = client.get(url)
      tmp['projectRoles']['roles'].pmap do |role_url|
        json = client.get role_url
        client.create(GoodData::ProjectRole, json)
      end
    end

    # Saves project
    def save
      data_to_send = raw_data.deep_dup
      data_to_send['project']['content'].delete('cluster')
      data_to_send['project']['content'].delete('isPublic')
      data_to_send['project']['content'].delete('state')
      response = if uri
                   client.post(PROJECT_PATH % pid, data_to_send)
                   client.get uri
                 else
                   result = client.post(PROJECTS_PATH, data_to_send)
                   client.get result['uri']
                 end
      @json = response
      self
    end

    # Checks if is project saved
    #
    # @return [Boolean] True if saved, false if not
    def saved?
      res = uri.nil?
      !res
    end

    # @param [String | Number | Object] Anything that you can pass to GoodData::Schedule[id]
    # @return [GoodData::Schedule | Array<GoodData::Schedule>] schedule instance or list
    def schedules(id = :all)
      GoodData::Schedule[id, project: self, client: client]
    end

    # Gets SLIs data
    #
    # @return [GoodData::Metadata] SLI Metadata
    def slis
      link = "#{data['links']['metadata']}#{SLIS_PATH}"

      # FIXME: Review what to do with passed extra argument
      Metadata.new client.get(link)
    end

    # Gets project state
    #
    # @return [String] Project state
    def state
      data['content']['state'].downcase.to_sym if data['content'] && data['content']['state']
    end

    Project.metadata_property_reader :summary, :title

    # Gets project title
    #
    # @return [String] Project title
    def title=(a_title)
      data['meta']['title'] = a_title if data['meta']
    end

    # Uploads file to project
    #
    # @param file File to be uploaded
    # @param schema Schema to be used
    def upload(file, dataset_blueprint, mode = 'FULL')
      dataset_blueprint.upload file, self, mode
    end

    def uri
      data['links']['self'] if data && data['links'] && data['links']['self']
    end

    # List of users in project
    #
    # @return [Array<GoodData::User>] List of users
    def users
      tmp = client.get @json['project']['links']['users']
      tmp['users'].map do |user|
        client.factory.create(GoodData::Membership, user)
      end
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
          d = GoodData::Domain[domain_name, {:client => client}]
          domain = {
            :domain => d,
            :users => d.users(:client => client)
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
      list.pmap do |user|
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

      client.post url, payload
    end

    alias_method :add_user, :set_user_roles

    # Update list of users
    #
    # @param list List of users to be updated
    # @param role_list Optional list of cached roles to prevent unnecessary server round-trips
    def set_users_roles(list, role_list = roles)
      list.pmap do |user_hash|
        user = user_hash[:user]
        roles = user_hash[:role] || user_hash[:roles]
        {
          :user => user,
          :result => set_user_roles(user, roles)
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
    def validate(filters = %w(ldm pdm metric_filter invalid_objects))
      response = client.post "#{md['validate-project']}", 'validateProject' => filters
      polling_link = response['asyncTask']['link']['poll']
      client.poll_on_response(polling_link) do |body|
        body['wTaskStatus'] && body['wTaskStatus']['status'] == 'RUNNING'
      end
    end
  end
end
