# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'csv'
require 'zip'
require 'fileutils'
require 'multi_json'
require 'pmap'
require 'zip'

require_relative '../exceptions/no_project_error'

require_relative '../helpers/auth_helpers'

require_relative '../rest/resource'
require_relative '../mixins/author'
require_relative '../mixins/contributor'
require_relative '../mixins/rest_resource'
require_relative '../mixins/uri_getter'

require_relative 'process'
require_relative 'project_role'
require_relative 'blueprint/blueprint'

module GoodData
  class Project < Rest::Resource
    USERSPROJECTS_PATH = '/gdc/account/profile/%s/projects'
    PROJECTS_PATH = '/gdc/projects'
    PROJECT_PATH = '/gdc/projects/%s'
    SLIS_PATH = '/ldm/singleloadinterface'
    DEFAULT_INVITE_MESSAGE = 'Join us!'
    DEFAULT_ENVIRONMENT = 'PRODUCTION'

    EMPTY_OBJECT = {
      'project' => {
        'meta' => {
          'summary' => 'No summary'
        },
        'content' => {
          'guidedNavigation' => 1,
          'driver' => 'Pg',
          'environment' => GoodData::Helpers::AuthHelper.read_environment
        }
      }
    }

    attr_accessor :connection, :json

    include Mixin::Author
    include Mixin::Contributor
    include Mixin::UriGetter

    class << self
      # Returns an array of all projects accessible by
      # current user
      def all(opts = { client: GoodData.connection })
        c = client(opts)
        c.user.projects
      end

      # Returns a Project object identified by given string
      # The following identifiers are accepted
      #  - /gdc/md/<id>
      #  - /gdc/projects/<id>
      #  - <id>
      #
      def [](id, opts = { client: GoodData.connection })
        return id if id.instance_of?(GoodData::Project) || id.respond_to?(:project?) && id.project?

        if id == :all
          Project.all({ client: GoodData.connection }.merge(opts))
        else
          if id.to_s !~ %r{^(\/gdc\/(projects|md)\/)?[a-zA-Z\d]+$}
            fail(ArgumentError, 'wrong type of argument. Should be either project ID or path')
          end

          id = id.match(/[a-zA-Z\d]+$/)[0] if id =~ %r{/}

          c = client(opts)
          fail ArgumentError, 'No :client specified' if c.nil?

          response = c.get(PROJECT_PATH % id)
          c.factory.create(Project, response)
        end
      end

      def create_object(data = {})
        c = client(data)
        new_data = GoodData::Helpers.deep_dup(EMPTY_OBJECT).tap do |d|
          d['project']['meta']['title'] = data[:title]
          d['project']['meta']['summary'] = data[:summary] if data[:summary]
          d['project']['meta']['projectTemplate'] = data[:template] if data[:template]
          d['project']['content']['guidedNavigation'] = data[:guided_navigation] if data[:guided_navigation]

          token = data[:auth_token] || data[:token]

          d['project']['content']['authorizationToken'] = token if token
          d['project']['content']['driver'] = data[:driver] if data[:driver]
          d['project']['content']['environment'] = data[:environment] if data[:environment]
        end
        c.create(Project, new_data)
      end

      # Create a project from a given attributes
      # Expected keys:
      # - :title (mandatory)
      # - :summary
      # - :template (default /projects/blank)
      #
      def create(opts = { :client => GoodData.connection }, &block)
        GoodData.logger.info "Creating project #{opts[:title]}"

        c = client(opts)
        fail ArgumentError, 'No :client specified' if c.nil?

        opts = { :auth_token => Helpers::AuthHelper.read_token }.merge(opts)
        auth_token = opts[:auth_token] || opts[:token]
        fail ArgumentError, 'You have to provide your token for creating projects as :auth_token parameter' if auth_token.nil? || auth_token.empty?

        project = create_object(opts)
        project.save
        # until it is enabled or deleted, recur. This should still end if there is a exception thrown out from RESTClient. This sometimes happens from WebApp when request is too long
        while project.state.to_s != 'enabled'
          if project.deleted?
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

      def find(_opts = {}, client = GoodData::Rest::Client.client)
        user = client.user
        user.projects['projects'].map do |project|
          client.create(GoodData::Project, project)
        end
      end

      def create_from_blueprint(blueprint, options = {})
        GoodData::Model::ProjectCreator.migrate(options.merge(spec: blueprint, client: GoodData.connection))
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

    def add_dashboard(dashboard)
      GoodData::Dashboard.create(dashboard, :client => client, :project => self)
    end

    alias_method :create_dashboard, :add_dashboard

    def add_user_group(data)
      g = GoodData::UserGroup.create(data.merge(project: self))

      begin
        g.save
      rescue RestClient::Conflict
        user_groups(data[:name])
      end
    end

    alias_method :create_group, :add_user_group

    # Creates a metric in a project
    #
    # @param [options] Optional report options
    # @return [GoodData::Report] Instance of new report
    def add_metric(metric, options = {})
      default = { client: client, project: self }
      if metric.is_a?(String)
        GoodData::Metric.xcreate(metric, options.merge(default))
      else
        GoodData::Metric.xcreate(options[:expression], metric.merge(options.merge(default)))
      end
    end

    alias_method :create_metric, :add_metric

    alias_method :add_measure, :add_metric
    alias_method :create_measure, :add_metric

    # Creates new instance of report in context of project
    #
    # @param [options] Optional report options
    # @return [GoodData::Report] Instance of new report
    def add_report(options = {})
      rep = GoodData::Report.create(options.merge(client: client, project: self))
      rep.save
    end

    alias_method :create_report, :add_report

    # Creates new instance of report definition in context of project
    # This report definition can be used for creating of GoodData::Report
    #
    # @param [json] Raw report definition json
    # @return [GoodData::ReportDefinition] Instance of new report definition
    def add_report_definition(json)
      rd = GoodData::ReportDefinition.new(json)
      rd.client = client
      rd.project = self
      rd.save
    end

    alias_method :create_report_definition, :add_report_definition

    # Returns an indication whether current user is admin in this project
    #
    # @return [Boolean] True if user has admin role in the project, false otherwise.
    def am_i_admin?
      user_has_role?(client.user, 'admin')
    end

    # Helper for getting attributes of a project
    #
    # @param [String | Number | Object] Anything that you can pass to GoodData::Attribute[id]
    # @return [GoodData::Attribute | Array<GoodData::Attribute>] fact instance or list
    def attributes(id = :all)
      GoodData::Attribute[id, project: self, client: client]
    end

    def attribute_by_identifier(identifier)
      GoodData::Attribute.find_first_by_identifier(identifier, project: self, client: client)
    end

    def attributes_by_identifier(identifier)
      GoodData::Attribute.find_by_identifier(identifier, project: self, client: client)
    end

    def attribute_by_title(title)
      GoodData::Attribute.find_first_by_title(title, project: self, client: client)
    end

    def attributes_by_title(title)
      GoodData::Attribute.find_by_title(title, project: self, client: client)
    end

    # Gets project blueprint from the server
    #
    # @return [GoodData::ProjectRole] Project role if found
    def blueprint(options = {})
      result = client.get("/gdc/projects/#{pid}/model/view", params: { includeDeprecated: true, includeGrain: true })
      polling_url = result['asyncTask']['link']['poll']
      model = client.poll_on_code(polling_url, options)
      bp = GoodData::Model::FromWire.from_wire(model)
      bp.title = title
      bp
    end

    # Returns web interface URI of project
    #
    # @return [String] Project URL
    def browser_uri(options = {})
      grey = options[:grey]
      server = client.connection.server_url
      if grey
        "#{server}#{uri}"
      else
        "#{server}/#s=#{uri}"
      end
    end

    # Clones project
    #
    # @param options [Hash] Export options
    # @option options [Boolean] :data Clone project with data
    # @option options [Boolean] :users Clone project with users
    # @option options [String] :authorized_users Comma separated logins of authorized users. Users that can use the export
    # @return [GoodData::Project] Newly created project
    def clone(options = {})
      a_title = options[:title] || "Clone of #{title}"

      begin
        # Create the project first so we know that it is passing.
        # What most likely is wrong is the token and the export actaully takes majority of the time
        new_project = GoodData::Project.create(options.merge(:title => a_title, :client => client, :driver => content[:driver]))
        export_token = export_clone(options)
        new_project.import_clone(export_token)
      rescue
        new_project.delete if new_project
        raise
      end
    end

    # Gives you list of datasets. These are not blueprint datasets but model datasets coming from meta
    # data server.
    #
    # @param id [Symbol | String | GoodData::MdObject] Export options
    # @return [Array<GoodData::Dataset> | GoodData::Dataset] Dataset or list of datasets in the project
    def datasets(id = :all)
      GoodData::Dataset[id, project: self, client: client]
    end

    def dimensions(id = :all)
      GoodData::Dimension[id, client: client, project: self]
    end

    # Export a clone from a project to be later imported.
    # If you do not want to do anything special and you do not need fine grained
    # controle use clone method which does all the heavy lifting for you.
    #
    # @param options [Hash] Export options
    # @option options [Boolean] :data Clone project with data
    # @option options [Boolean] :users Clone project with users
    # @option options [String] :authorized_users Comma separated logins of authorized users. Users that can use the export
    # @return [String] token of the export
    def export_clone(options = {})
      with_data = options[:data].nil? ? true : options[:data]
      with_users = options[:users].nil? ? false : options[:users]

      export = {
        :exportProject => {
          :exportUsers => with_users ? 1 : 0,
          :exportData => with_data ? 1 : 0
        }
      }
      export[:exportProject][:authorizedUsers] = options[:authorized_users] if options[:authorized_users]

      result = client.post("/gdc/md/#{obj_id}/maintenance/export", export)
      status_url = result['exportArtifact']['status']['uri']
      client.poll_on_response(status_url) do |body|
        body['taskState']['status'] == 'RUNNING'
      end
      result['exportArtifact']['token']
    end

    def user_groups(id = :all, options = {})
      GoodData::UserGroup[id, options.merge(project: self)]
    end

    # Imports a clone into current project. The project has to be freshly
    # created.
    #
    # @param export_token [String] Export token of the package to be imported
    # @return [Project] current project
    def import_clone(export_token, options = {})
      import = {
        :importProject => {
          :token => export_token
        }
      }

      result = client.post("/gdc/md/#{obj_id}/maintenance/import", import)
      status_url = result['uri']
      client.poll_on_response(status_url, options) do |body|
        body['taskState']['status'] == 'RUNNING'
      end
      self
    end

    def compute_report(spec = {})
      GoodData::ReportDefinition.execute(spec.merge(client: client, project: self))
    end

    def compute_metric(expression)
      GoodData::Metric.xexecute(expression, client: client, project: self)
    end

    alias_method :compute_measure, :compute_metric

    def create_schedule(process, date, executable, options = {})
      s = GoodData::Schedule.create(process, date, executable, options.merge(client: client, project: self))
      s.save
    end

    def create_variable(data)
      GoodData::Variable.create(data, client: client, project: self)
    end

    # Helper for getting dashboards of a project
    #
    # @param id [String | Number | Object] Anything that you can pass to GoodData::Dashboard[id]
    # @return [GoodData::Dashboard | Array<GoodData::Dashboard>] dashboard instance or list
    def dashboards(id = :all)
      GoodData::Dashboard[id, project: self, client: client]
    end

    def data_permissions(id = :all)
      GoodData::MandatoryUserFilter[id, client: client, project: self]
    end

    # Deletes project
    def delete
      fail "Project '#{title}' with id #{uri} is already deleted" if deleted?
      client.delete(uri)
    end

    # Returns true if project is in deleted state
    #
    # @return [Boolean] Returns true if object deleted. False otherwise.
    def deleted?
      state == :deleted
    end

    # Helper for getting rid of all data in the project
    #
    # @option options [Boolean] :force has to be added otherwise the operation is not performed
    # @return [Array] Result of executing MAQLs
    def delete_all_data(options = {})
      return false unless options[:force]
      datasets.pmap(&:delete_data)
    end

    # Deletes dashboards for project
    def delete_dashboards
      Dashboard.all.map { |data| Dashboard[data['link']] }.each(&:delete)
    end

    def deploy_process(path, options = {})
      GoodData::Process.deploy(path, options.merge(client: client, project: self))
    end

    # Executes DML expression. See (https://developer.gooddata.com/article/deleting-records-from-datasets)
    # for some examples and explanations
    #
    # @param dml [String] DML expression
    # @return [Hash] Result of executing DML
    def execute_dml(dml, options = {})
      uri = "/gdc/md/#{pid}/dml/manage"
      result = client.post(uri, manage: { maql: dml })
      polling_uri = result['uri']

      client.poll_on_response(polling_uri, options) do |body|
        body && body['taskState'] && body['taskState']['status'] == 'WAIT'
      end
    end

    # Executes MAQL expression and waits for it to be finished.
    #
    # @param maql [String] MAQL expression
    # @return [Hash] Result of executing MAQL
    def execute_maql(maql, options = {})
      ldm_links = client.get(md[GoodData::Model::LDM_CTG])
      ldm_uri = Links.new(ldm_links)[GoodData::Model::LDM_MANAGE_CTG]
      response = client.post(ldm_uri, manage: { maql: maql })
      polling_uri = response['entries'].first['link']

      client.poll_on_response(polling_uri, options) do |body|
        body && body['wTaskStatus'] && body['wTaskStatus']['status'] == 'RUNNING'
      end
    end

    # Helper for getting facts of a project
    #
    # @param [String | Number | Object] Anything that you can pass to GoodData::Fact[id]
    # @return [GoodData::Fact | Array<GoodData::Fact>] fact instance or list
    def facts(id = :all)
      GoodData::Fact[id, project: self, client: client]
    end

    def fact_by_title(title)
      GoodData::Fact.find_first_by_title(title, project: self, client: client)
    end

    def facts_by_title(title)
      GoodData::Fact.find_by_title(title, project: self, client: client)
    end

    def find_attribute_element_value(uri)
      GoodData::Attribute.find_element_value(uri, client: client, project: self)
    end

    # Get WebDav directory for project data
    # @return [String]
    def project_webdav_path
      client.project_webdav_path(:project => self)
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

    # Gets user by its login or uri in various shapes
    # It does not find by other information because that is not unique. If you want to search by name or email please
    # use fuzzy_get_user.
    #
    # @param [String] name Name to look for
    # @param [Array<GoodData::User>]user_list Optional cached list of users used for look-ups
    # @return [GoodDta::Membership] User
    def get_user(slug, user_list = users)
      search_crit = if slug.respond_to?(:login)
                      slug.login || slug.uri
                    elsif slug.is_a?(Hash)
                      slug[:login] || slug[:uri]
                    else
                      slug
                    end
      return nil unless search_crit
      user_list.find do |user|
        user.uri == search_crit.downcase ||
          user.login.downcase == search_crit.downcase
      end
    end

    def upload_file(file, options = {})
      GoodData.upload_to_project_webdav(file, options.merge(project: self))
    end

    def download_file(file, where)
      GoodData.download_from_project_webdav(file, where, project: self)
    end

    def environment
      json['project']['content']['environment']
    end

    # Gets user by its email, full_name, login or uri
    alias_method :member, :get_user

    # Gets user by its email, full_name, login or uri.
    #
    # @param [String] name Name to look for
    # @param [Array<GoodData::User>]user_list Optional cached list of users used for look-ups
    # @return [GoodDta::Membership] User
    def fuzzy_get_user(name, user_list = users)
      return name if name.instance_of?(GoodData::Membership)
      return member(name) if name.instance_of?(GoodData::Profile)
      name = name.is_a?(Hash) ? name[:login] || name[:uri] : name
      return nil unless name
      name.downcase!
      user_list.select do |user|
        user.uri.downcase == name ||
          user.login.downcase == name ||
          user.email.downcase == name
      end
      nil
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
      client.post(url, data)
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
    def labels(id = :all, opts = {})
      if id == :all
        attributes.pmapcat(&:labels).uniq
      else
        GoodData::Label[id, opts.merge(project: self, client: client)]
      end
    end

    def md
      @md ||= client.create(Links, client.get(data['links']['metadata']))
    end

    # Get data from project specific metadata storage
    #
    # @param [Symbol | String] :all or nothing for all keys or a string for value of specific key
    # @return [Hash] key Hash of stored data
    def metadata(key = :all)
      GoodData::ProjectMetadata[key, client: client, project: self]
    end

    # Set data for specific key in project specific metadata storage
    #
    # @param [String] key key of the value to be stored
    # @return [String] val value to be stored
    def set_metadata(key, val)
      GoodData::ProjectMetadata[key, client: client, project: self] = val
    end

    # Helper for getting metrics of a project
    #
    # @return [Array<GoodData::Metric>] matric instance or list
    def metrics(id = :all, opts = { :full => true })
      GoodData::Metric[id, opts.merge(project: self, client: client)]
    end

    alias_method :measures, :metrics

    def metric_by_title(title)
      GoodData::Metric.find_first_by_title(title, project: self, client: client)
    end

    alias_method :measure_by_title, :metric_by_title

    def metrics_by_title(title)
      GoodData::Metric.find_by_title(title, project: self, client: client)
    end

    alias_method :measures_by_title, :metrics_by_title

    # Checks if the profile is member of project
    #
    # @param [GoodData::Profile] profile - Profile to be checked
    # @param [Array<GoodData::Membership>] list Optional list of members to check against
    # @return [Boolean] true if is member else false
    def member?(profile, list = members)
      !member(profile, list).nil?
    end

    def members?(profiles, list = members)
      profiles.map { |p| member?(p, list) }
    end

    # Gets raw resource ID
    #
    # @return [String] Raw resource ID
    def obj_id
      uri.split('/').last
    end

    alias_method :pid, :obj_id

    # Helper for getting objects of a project
    #
    # @return [Array<GoodData::MdObject>] object instance or list
    def objects(id, opts = {})
      GoodData::MdObject[id, opts.merge(project: self, client: client)]
    end

    # Transfer objects from one project to another
    #
    # @param [Array<GoodData::MdObject | String>, String, GoodData::MdObject] objs Any representation of the object or a list of those
    # @param [Hash] options The options to migration.
    # @option options [Number] :time_limit Time in seconds before the blocking call will fail. See GoodData::Rest::Client.poll_on_response for additional details
    # @option options [Number] :sleep_interval Interval between polls on the status of the migration.
    # @return [String] Returns token that you can use as input for object_import
    def objects_export(objs, options = {})
      fail 'Nothing to migrate. You have to pass list of objects, ids or uris that you would like to migrate' if objs.nil?
      objs = Array(objs)
      fail 'Nothing to migrate. The list you provided is empty' if objs.empty?

      objs = objs.pmap { |obj| [obj, objects(obj)] }
      fail ObjectsExportError, "Exporting objects failed with messages. Object #{objs.select { |_, obj| obj.nil? }.map { |o, _| o }.join(', ')} could not be found." if objs.any? { |_, obj| obj.nil? }
      export_payload = {
        :partialMDExport => {
          :uris => objs.map { |_, obj| obj.uri }
        }
      }
      result = client.post("#{md['maintenance']}/partialmdexport", export_payload)
      polling_url = result['partialMDArtifact']['status']['uri']
      token = result['partialMDArtifact']['token']

      polling_result = client.poll_on_response(polling_url, options) do |body|
        body['wTaskStatus'] && body['wTaskStatus']['status'] == 'RUNNING'
      end
      if polling_result['wTaskStatus'] && polling_result['wTaskStatus']['status'] == 'ERROR'
        messages = GoodData::Helpers.interpolate_error_messages(polling_result['wTaskStatus']['messages']).join(' ')
        fail ObjectsExportError, "Exporting objects failed with messages. #{messages}"
      end
      token
    end

    # Import objects from import token. If you do not need specifically this method what you are probably looking for is transfer_objects. This is a lower level method.
    #
    # @param [String] token Migration token ID
    # @param [Hash] options The options to migration.
    # @option options [Number] :time_limit Time in seconds before the blocking call will fail. See GoodData::Rest::Client.poll_on_response for additional details
    # @option options [Number] :sleep_interval Interval between polls on the status of the migration.
    # @return [Boolean] Returns true if it succeeds or throws exceoption
    def objects_import(token, options = {})
      fail 'You need to provide a token for object import' if token.blank?

      import_payload = {
        :partialMDImport => {
          :token => token,
          :overwriteNewer => '1',
          :updateLDMObjects => '0'
        }
      }

      result = client.post("#{md['maintenance']}/partialmdimport", import_payload)
      polling_url = result['uri']

      polling_result = client.poll_on_response(polling_url, options) do |body|
        body['wTaskStatus'] && body['wTaskStatus']['status'] == 'RUNNING'
      end

      if polling_result['wTaskStatus']['status'] == 'ERROR'
        messages = GoodData::Helpers.interpolate_error_messages(polling_result['wTaskStatus']['messages']).join(' ')
        fail ObjectsImportError, "Importing objects failed with messages. #{messages}"
      end
      true
    end

    # Transfer objects from one project to another
    #
    # @param [Array<GoodData::MdObject | String>, String, GoodData::MdObject] objects Any representation of the object or a list of those
    # @param [Hash] options The options to migration.
    # @option options [GoodData::Project | String | Array<String> | Array<GoodData::Project>] :project Project(s) to migrate to
    # @option options [Number] :batch_size Number of projects that are migrated at the same time. Default is 10
    #
    # @return [Boolean | Array<Hash>] Return either true or throws exception if you passed only one project. If you provided an array returns list of hashes signifying sucees or failure. Take note that in case of list of projects it does not throw exception
    def partial_md_export(objects, options = {})
      projects = options[:project]
      batch_size = options[:batch_size] || 10
      token = objects_export(objects)

      if projects.is_a?(Array)
        projects.each_slice(batch_size).flat_map do |batch|
          batch.pmap do |proj|
            target_project = client.projects(proj)
            begin
              target_project.objects_import(token, options)
              {
                project: target_project,
                result: true
              }
            rescue GoodData::ObjectsImportError => e
              {
                project: target_project,
                result: false,
                reason: e.message
              }
            end
          end
        end
      else
        target_project = client.projects(projects)
        target_project.objects_import(token, options)
      end
    end

    alias_method :transfer_objects, :partial_md_export

    # Helper for getting processes of a project
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
        [ds, ds.count(self)]
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

    # Method used for walking through objects in project and trying to replace all occurences of some object for another object. This is typically used as a means for exchanging Date dimensions.
    #
    # @param mapping [Array<Array>] Mapping specifying what should be exchanged for what. As mapping should be used output of GoodData::Helpers.prepare_mapping.
    def replace_from_mapping(mapping, opts = {})
      default = {
        :purge => false,
        :dry_run => false
      }
      opts = default.merge(opts)
      dry_run = opts[:dry_run]

      if opts[:purge]
        GoodData.logger.info 'Purging old project definitions'
        reports.peach(&:purge_report_of_unused_definitions!)
      end

      fail ArgumentError, 'No mapping specified' if mapping.blank?
      rds = report_definitions

      {
        # data_permissions: data_permissions,
        variables: variables,
        dashboards: dashboards,
        metrics: metrics,
        report_definitions: rds
      }.each do |key, collection|
        puts "Replacing #{key}"
        collection.peach do |item|
          new_item = item.replace(mapping)
          if new_item.json != item.json
            if dry_run
              GoodData.logger.info "Would save #{new_item.uri}. Running in dry run mode"
            else
              GoodData.logger.info "Saving #{new_item.uri}"
              new_item.save
            end
          end
        end
      end

      GoodData.logger.info 'Replacing hidden metrics'
      local_metrics = rds.pmapcat { |rd| rd.using('metric') }.select { |m| m['deprecated'] == '1' }
      puts "Found #{local_metrics.count} metrics"
      local_metrics.pmap { |m| metrics(m['link']) }.peach do |item|
        new_item = item.replace(mapping)
        if new_item.json != item.json
          if dry_run
            GoodData.logger.info "Would save #{new_item.uri}. Running in dry run mode"
          else
            GoodData.logger.info "Saving #{new_item.uri}"
            new_item.save
          end
        end
      end

      GoodData.logger.info 'Replacing variable values'
      variables.each do |var|
        var.values.peach do |val|
          val.replace(mapping).save unless dry_run
        end
      end
      nil
    end

    # Helper for getting reports of a project
    #
    # @param [String | Number | Object] Anything that you can pass to GoodData::Report[id]
    # @return [GoodData::Report | Array<GoodData::Report>] report instance or list
    def reports(id = :all)
      GoodData::Report[id, project: self, client: client]
    end

    # Helper for getting report definitions of a project
    #
    # @param [String | Number | Object] Anything that you can pass to GoodData::ReportDefinition[id]
    # @return [GoodData::ReportDefinition | Array<GoodData::ReportDefinition>] report definition instance or list
    def report_definitions(id = :all, options = {})
      GoodData::ReportDefinition[id, options.merge(project: self, client: client)]
    end

    # Gets the list or project roles
    #
    # @return [Array<GoodData::ProjectRole>] List of roles
    def roles
      url = "/gdc/projects/#{pid}/roles"

      tmp = client.get(url)
      tmp['projectRoles']['roles'].pmap do |role_url|
        json = client.get role_url
        client.create(GoodData::ProjectRole, json, project: self)
      end
    end

    # Saves project
    def save
      data_to_send = GoodData::Helpers.deep_dup(raw_data)
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
    def upload(data, blueprint, dataset_name, options = {})
      GoodData::Model.upload_data(data, blueprint, dataset_name, options.merge(client: client, project: self))
    end

    def upload_multiple(data, blueprint, options = {})
      GoodData::Model.upload_multiple_data(data, blueprint, options.merge(client: client, project: self))
    end

    def uri
      data['links']['self'] if data && data['links'] && data['links']['self']
    end

    # List of user filters within this project
    #
    # @return [Array<GoodData::MandatoryUserFilter>] List of mandatory user
    def user_filters
      url = "/gdc/md/#{pid}/userfilters"

      tmp = client.get(url)
      tmp['userFilters']['items'].pmap do |filter|
        client.create(GoodData::MandatoryUserFilter, filter, project: self)
      end
    end

    # List of users in project
    #
    #
    # @return [Array<GoodData::User>] List of users
    def users(opts = {})
      client = client(opts)
      Enumerator.new do |y|
        offset = opts[:offset] || 0
        limit = opts[:limit] || 1_000
        loop do
          tmp = client.get("/gdc/projects/#{pid}/users", params: { offset: offset, limit: limit })
          tmp['users'].each do |user_data|
            user = client.create(GoodData::Membership, user_data, project: self)
            y << user if opts[:all] || user && user.enabled?
          end
          break if tmp['users'].count < limit
          offset += limit
        end
      end
    end

    alias_method :members, :users

    def whitelist_users(new_users, users_list, whitelist, mode = :exclude)
      return [new_users, users_list] unless whitelist

      new_whitelist_proc = proc do |user|
        whitelist.any? { |wl| wl.is_a?(Regexp) ? user[:login] =~ wl : user[:login].include?(wl) }
      end

      whitelist_proc = proc do |user|
        whitelist.any? { |wl| wl.is_a?(Regexp) ? user.login =~ wl : user.login.include?(wl) }
      end

      if mode == :include
        [new_users.select(&new_whitelist_proc), users_list.select(&whitelist_proc)]
      elsif mode == :exclude
        [new_users.reject(&new_whitelist_proc), users_list.reject(&whitelist_proc)]
      end
    end

    # Imports users
    def import_users(new_users, options = {})
      role_list = roles
      users_list = users(all: true)
      new_users = new_users.map { |x| (x.is_a?(Hash) && x[:user] && x[:user].to_hash.merge(role: x[:role])) || x.to_hash }

      GoodData.logger.warn("Importing users to project (#{pid})")

      whitelisted_new_users, whitelisted_users = whitelist_users(new_users.map(&:to_hash), users_list, options[:whitelists])

      # First check that if groups are provided we have them set up
      check_groups(new_users.map(&:to_hash).flat_map { |u| u[:user_group] || [] }.uniq)

      # conform the role on list of new users so we can diff them with the users coming from the project
      diffable_new_with_default_role = whitelisted_new_users.map do |u|
        u[:role] = Array(u[:role] || u[:roles] || 'readOnlyUser')
        u
      end

      intermediate_new = diffable_new_with_default_role.map do |u|
        u[:role] = u[:role].map do |r|
          role = get_role(r, role_list)
          role && role.uri
        end

        if u[:role].all?(&:nil?)
          u[:type] = :error
          u[:reason] = 'Invalid role(s) specified'
        else
          u[:type] = :ok
        end

        u[:status] = 'ENABLED'
        u
      end

      intermediate_new_by_type = intermediate_new.group_by { |i| i[:type] }
      diffable_new = intermediate_new_by_type[:ok] || []

      # Diff users. Only login and role is important for the diff
      diff = GoodData::Helpers.diff(whitelisted_users, diffable_new, key: :login, fields: [:login, :role, :status])

      # Create new users
      u = diff[:added].map { |x| { user: x, role: x[:role] } }

      results = []
      GoodData.logger.warn("Creating #{diff[:added].count} users in project (#{pid})")
      results.concat(create_users(u, roles: role_list, project_users: whitelisted_users))

      # # Update existing users
      GoodData.logger.warn("Updating #{diff[:changed].count} users in project (#{pid})")
      list = diff[:changed].map { |x| { user: x[:new_obj], role: x[:new_obj][:role] || x[:new_obj][:roles] } }
      results.concat(set_users_roles(list, roles: role_list, project_users: whitelisted_users))

      # Remove old users
      to_remove = diff[:removed].reject { |user| user[:status] == 'DISABLED' || user[:status] == :disabled }
      GoodData.logger.warn("Removing #{to_remove.count} users from project (#{pid})")
      results.concat(disable_users(to_remove))

      # reassign to groups
      mappings = new_users.map(&:to_hash).flat_map do |user|
        groups = user[:user_group] || []
        groups.map { |g| [user[:login], g] }
      end
      unless mappings.empty?
        users_lookup = users.reduce({}) do |a, e|
          a[e.login] = e
          a
        end
        mappings.group_by { |_, g| g }.each do |g, mapping|
          # find group + set users
          # CARE YOU DO NOT KNOW URI
          user_groups(g).set_members(mapping.map { |user, _| user }.map { |login| users_lookup[login] && users_lookup[login].uri })
        end
        mentioned_groups = mappings.map(&:last).uniq
        groups_to_cleanup = user_groups.reject { |g| mentioned_groups.include?(g.name) }
        # clean all groups not mentioned with exception of whitelisted users
        groups_to_cleanup.each do |g|
          g.set_members(whitelist_users(g.members.map(&:to_hash), [], options[:whitelists], :include).first.map { |x| x[:uri] })
        end
      end
      results
    end

    def disable_users(list)
      list = list.map(&:to_hash)
      url = "#{uri}/users"
      payloads = list.map do |u|
        generate_user_payload(u[:uri], 'DISABLED')
      end

      payloads.each_slice(100).mapcat do |payload|
        result = client.post(url, 'users' => payload)
        result['projectUsersUpdateResult'].mapcat { |k, v| v.map { |x| { type: k.to_sym, uri: x } } }
      end
    end

    def check_groups(specified_groups)
      groups = user_groups.map(&:name)
      missing_groups = specified_groups - groups
      fail "All groups have to be specified before you try to import users. Groups that are currently in project are #{groups.join(',')} and you asked for #{missing_groups.join(',')}" unless missing_groups.empty?
    end

    # Update user
    #
    # @param user User to be updated
    # @param desired_roles Roles to be assigned to user
    # @param role_list Optional cached list of roles used for lookups
    def set_user_roles(login, desired_roles, options = {})
      user_uri, roles = resolve_roles(login, desired_roles, options)
      url = "#{uri}/users"
      payload = generate_user_payload(user_uri, 'ENABLED', roles)
      res = client.post(url, payload)
      failure = GoodData::Helpers.get_path(res, %w(projectUsersUpdateResult failed))
      fail ArgumentError, "User #{user_uri} could not be aded. #{failure.first['message']}" unless failure.blank?
      res
    end
    alias_method :add_user, :set_user_roles

    # Update list of users
    #
    # @param list List of users to be updated
    # @param role_list Optional list of cached roles to prevent unnecessary server round-trips
    def set_users_roles(list, options = {})
      return [] if list.empty?
      role_list = options[:roles] || roles
      project_users = options[:project_users] || users

      intermediate_users = list.flat_map do |user_hash|
        user = user_hash[:user] || user_hash[:login]
        desired_roles = user_hash[:role] || user_hash[:roles] || 'readOnlyUser'
        begin
          login, roles = resolve_roles(user, desired_roles, options.merge(project_users: project_users, roles: role_list))
          [{ :type => :successful, user: login, roles: roles }]
        rescue => e
          [{ :type => :failed, :reason => e.message, user: login, roles: roles }]
        end
      end

      # User can fail pre sending to API during resolving roles. We add only users that passed that step.
      users_by_type = intermediate_users.group_by { |u| u[:type] }
      users_to_add = users_by_type[:successful] || []

      payloads = users_to_add.map { |u| generate_user_payload(u[:user], 'ENABLED', u[:roles]) }
      results = payloads.each_slice(100).map do |payload|
        client.post("#{uri}/users", 'users' => payload)
      end
      # this ugly line turns the hash of errors into list of errors with types so we can process them easily
      typed_results = results.flat_map { |x| x['projectUsersUpdateResult'].flat_map { |k, v| v.map { |v_2| v_2.is_a?(String) ? { type: k.to_sym, user: v_2 } : GoodData::Helpers.symbolize_keys(v_2).merge(type: k.to_sym) } } }
      # we have to concat errors from role resolution and API result
      typed_results + (users_by_type[:failed] || [])
    end

    alias_method :add_users, :set_users_roles
    alias_method :create_users, :set_users_roles

    def add_data_permissions(filters, options = {})
      GoodData::UserFilterBuilder.execute_mufs(filters, { client: client, project: self }.merge(options))
    end

    def add_variable_permissions(filters, var, options = {})
      GoodData::UserFilterBuilder.execute_variables(filters, var, { client: client, project: self }.merge(options))
    end

    # Run validation on project
    # Valid settins for validation are (default all):
    # ldm - Checks the consistency of LDM objects.
    # pdm Checks LDM to PDM mapping consistency, also checks PDM reference integrity.
    # metric_filter - Checks metadata for inconsistent metric filters.
    # invalid_objects - Checks metadata for invalid/corrupted objects.
    # asyncTask response
    def validate(filters = %w(ldm pdm metric_filter invalid_objects), options = {})
      response = client.post "#{md['validate-project']}", 'validateProject' => filters
      polling_link = response['asyncTask']['link']['poll']
      client.poll_on_response(polling_link, options) do |body|
        body['wTaskStatus'] && body['wTaskStatus']['status'] == 'RUNNING'
      end
    end

    def variables(id = :all, options = { client: client, project: self })
      GoodData::Variable[id, options]
    end

    def update_from_blueprint(blueprint, options = {})
      GoodData::Model::ProjectCreator.migrate(options.merge(spec: blueprint, token: options[:auth_token], client: client, project: self))
    end

    def resolve_roles(login, desired_roles, options = {})
      user = if login.is_a?(String) && login.include?('@')
               '/gdc/account/profile/' + login
             elsif login.is_a?(String)
               login
             elsif login.is_a?(Hash) && login[:login]
               '/gdc/account/profile/' + login[:login]
             elsif login.is_a?(Hash) && login[:uri]
               login[:uri]
             elsif login.respond_to?(:uri) && login.uri
               login.uri
             elsif login.respond_to?(:login) && login.login
               '/gdc/account/profile/' + login.login
             else
               fail "Unsupported user specification #{login}"
             end

      role_list = options[:roles] || roles
      desired_roles = Array(desired_roles)
      roles = desired_roles.map do |role_name|
        role = get_role(role_name, role_list)
        fail ArgumentError, "Invalid role '#{role_name}' specified for user '#{user.email}'" if role.nil?
        role.uri
      end
      [user, roles]
    end

    private

    def generate_user_payload(user_uri, status = 'ENABLED', roles_uri = nil)
      payload = {
        'user' => {
          'content' => {
            'status' => status
          },
          'links' => {
            'self' => user_uri
          }
        }
      }
      payload['user']['content']['userRoles'] = roles_uri if roles_uri
      payload
    end
  end
end
