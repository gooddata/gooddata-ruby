# encoding: UTF-8

require 'csv'
require 'zip'
require 'fileutils'
require 'multi_json'
require 'pmap'
require 'zip'

require_relative '../exceptions/no_project_error'

require_relative '../rest/resource'
require_relative '../mixins/author'
require_relative '../mixins/contributor'
require_relative '../mixins/rest_resource'

require_relative 'process'
require_relative 'project_role'
require_relative 'blueprint/blueprint'

module GoodData
  class Project < GoodData::Rest::Resource
    USERSPROJECTS_PATH = '/gdc/account/profile/%s/projects'
    PROJECTS_PATH = '/gdc/projects'
    PROJECT_PATH = '/gdc/projects/%s'
    SLIS_PATH = '/ldm/singleloadinterface'
    DEFAULT_INVITE_MESSAGE = 'Join us!'

    EMPTY_OBJECT = {
      'project' => {
        'meta' => {
          'summary' => 'No summary'
        },
        'content' => {
          'guidedNavigation' => 1,
          'driver' => 'Pg',
          'environment' => 'PRODUCTION'
        }
      }
    }

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
        new_data = EMPTY_OBJECT.deep_dup.tap do |d|
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
      result = client.get("/gdc/projects/#{pid}/model/view")
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
      if grey
        client.connection.url + uri
      else
        client.connection.url + '#s=' + uri
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
        new_project = GoodData::Project.create(options.merge(:title => a_title, :client => client))
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

    def create_schedule(process, date, executable, options = {})
      GoodData::Schedule.create(process, date, executable, options.merge(client: client, project: self))
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
      fail "Project '#{title}' with id #{uri} is already deleted" if state == :deleted
      client.delete(uri)
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

    # Get WebDav directory for user data
    # @return [String]
    def user_webdav_path
      u = URI(links['uploads'])
      URI.join(u.to_s.chomp(u.path.to_s), '/uploads/')
    end

    def upload_file(file)
      GoodData.upload_to_project_webdav(file, project: self)
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

    def metric_by_title(title)
      GoodData::Metric.find_first_by_title(title, project: self, client: client)
    end

    def metrics_by_title(title)
      GoodData::Metric.find_by_title(title, project: self, client: client)
    end

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

    def partial_md_export(objs, options = {})
      fail 'Nothing to migrate. You have to pass list of objects, ids or uris that you would like to migrate' if objs.nil?
      objs = [objs] unless objs.is_a?(Array)
      fail 'Nothing to migrate. The list you provided is empty' if objs.empty?

      target_project = options[:project]
      fail 'You have to provide a project instance or project pid to migrate to' if target_project.nil?
      target_project = client.projects(target_project)
      objs = objs.pmap { |obj| objects(obj) }
      export_payload = {
        :partialMDExport => {
          :uris => objs.map(&:uri)
        }
      }
      result = client.post("#{md['maintenance']}/partialmdexport", export_payload)
      polling_url = result['partialMDArtifact']['status']['uri']
      token = result['partialMDArtifact']['token']

      polling_result = client.poll_on_response(polling_url, options) do |body|
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

      result = client.post("#{target_project.md['maintenance']}/partialmdimport", import_payload)
      polling_url = result['uri']

      client.poll_on_response(polling_url, options) do |body|
        body['wTaskStatus'] && body['wTaskStatus']['status'] == 'RUNNING'
      end

      fail 'Exporting objects failed' if polling_result['wTaskStatus']['status'] == 'ERROR'
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

    DEFAULT_REPLACE_DATE_DIMENSION_OPTIONS = {
      :old => nil,
      :new => nil,
      :purge => false,
      :dry_run => true,
      :mapping => {}
    }

    def replace_date_dimension(opts)
      fail ArgumentError, 'No :old dimension specified' if opts[:old].nil?
      fail ArgumentError, 'No :new dimension specified' if opts[:new].nil?

      # Merge with default options
      opts = DEFAULT_REPLACE_DATE_DIMENSION_OPTIONS.merge(opts)

      get_attribute = lambda do |attr|
        return attr if attr.is_a?(GoodData::Attribute)

        res = attribute_by_identifier(attr)
        return res if res

        attribute_by_title(attr)
      end

      if opts[:old] && opts[:new]
        fail ArgumentError, 'You specified both :old => :new and :mapping' if opts[:mapping] && !opts[:mapping].empty?

        attrs = attributes_by_title(/\(#{opts[:old]}\)$/)

        attrs.each do |old_attr|
          new_attr_title = old_attr.title.sub("(#{opts[:old]})", "(#{opts[:new]})")
          new_attr = attribute_by_title(new_attr_title)

          fail "Unable to find attribute '#{new_attr_title}' in date dimension '#{opts[:new]}'" if new_attr.nil?

          opts[:mapping][old_attr] = new_attr
        end
      end

      mufs = user_filters

      # Replaces string anywhere in JSON with another string and returns back new JSON
      json_replace = lambda do |object, old_uri, new_uri|
        old_json = JSON.generate(object.json)
        regexp_replace = Regexp.new(old_uri + '([^0-9])')

        new_json = old_json.gsub(regexp_replace, "#{new_uri}\\1")
        if old_json != new_json
          object.json = JSON.parse(new_json)
          object.save
        end
        object
      end

      # delete old report definitions (only the last version of each report is kept)
      if opts[:purge]
        GoodData.logger.info 'Purging old project definitions'
        reports.peach(&:purge_report_of_unused_definitions!)
      end

      fail ArgumentError, 'No :mapping specified' if opts[:mapping].nil? || opts[:mapping].empty?

      # Preprocess mapping, do necessary lookup
      mapping = {}
      opts[:mapping].each do |k, v|
        attr_src = get_attribute.call(k)
        attr_dest = get_attribute.call(v)

        fail ArgumentError, "Unable to find attribute with identifier '#{k}'" if attr_src.nil?
        fail ArgumentError, "Unable to find attribute with identifier '#{v}'" if attr_dest.nil?

        mapping[attr_src] = attr_dest
      end

      # Iterate over all date attributes
      mapping.each do |old_date, new_date|
        GoodData.logger.info "  replacing date attribute '#{old_date.title}' (#{old_date.uri}) with '#{new_date.title}' (#{new_date.uri})"

        # For each attribute prepare list of labels to replace
        labels_mapping = {}

        old_date.labels.each do |old_label|
          new_label_title = old_label.title.sub("(#{opts[:old]})", "(#{opts[:new]})")

          # Go through all labels, label_by_title has some issues
          new_date.json['attribute']['content']['displayForms'].each do |label_tmp|
            if label_tmp['meta']['title'] == new_label_title
              new_label = labels(label_tmp['meta']['uri'])
              labels_mapping[old_label] = new_label
            end
          end
        end

        # Now we should have all labels for this attribute and its replacement in new date dimension
        # First fix all affected metrics that are using this attribute
        dependent = old_date.usedby
        GoodData.logger.info 'Fixing metrics...'
        dependent.each do |dependent_object|
          next if dependent_object['category'] != 'metric'

          affected_metric = metrics(dependent_object['link'])

          GoodData.logger.info "Metric '#{dependent_object['title']}' (#{affected_metric.uri}) contains old date attribute '#{old_date.title}' ...replacing"
          affected_metric.replace(old_date.uri, new_date.uri)
          affected_metric.save unless opts[:dry_run]
        end

        # Then search which reports are still using this attribute after replacement in metric...
        dependent = old_date.usedby
        GoodData.logger.info 'Fixing reports (standard)...'
        dependent.each do |dependent_object|
          # This does not seem to work every time... some references are kept...
          next if dependent_object['category'] != 'reportDefinition'

          affected_rd = report_definitions(dependent_object['link'])

          GoodData.logger.info "reportDefinition (#{affected_rd.uri}) contains old date attribute '#{old_date.title}' ...replacing"
          affected_rd.replace(old_date.uri, new_date.uri)

          # Affected_rd.replace(labels_mapping) #not sure if this is working correctly, try to do it one by one
          labels_mapping.each_pair do |old_label, new_label|
            affected_rd.replace(old_label.uri, new_label.uri)
          end

          affected_rd.save unless opts[:dry_run]
        end

        # Then search which dashboards and reports are still using this attribute after standard replacement in reports...
        dependent = old_date.usedby
        GoodData.logger.info 'Fixing reports (force) & dashboards...'

        # If standard replace did not work, use force...
        dependent.each do |dependent_object|
          case dependent_object['category']
          when 'reportDefinition'
            affected_rd = report_definitions(dependent_object['link'])

            GoodData.logger.info "reportDefinition '#{affected_rd.title}' (#{affected_rd.uri}) still contains old date attribute '#{old_date.title}' ...replacing by force"
            json_replace.call(affected_rd, old_date.uri, new_date.uri)

            # Iterate over all labels
            labels_mapping.each_pair do |old_label, new_label|
              json_replace.call(affected_rd, old_label.uri, new_label.uri)
            end

            affected_rd.save unless opts[:dry_run]
          when 'projectDashboard'
            affected_dashboard = dashboards(dependent_object['link'])

            GoodData.logger.info "Dashboard '#{affected_dashboard.title}' (#{affected_dashboard.uri}) contains old date attribute '#{old_date.title}' ...replacing by force"
            json_replace.call(affected_dashboard, old_date.uri, new_date.uri)

            # Iterate over all labels
            labels_mapping.each_pair do |old_label, new_label|
              json_replace.call(affected_dashboard, old_label.uri, new_label.uri)
            end

            affected_dashboard.save unless opts[:dry_run]
          end
        end

        mufs.each do |muf|
          json_replace.call(muf, old_date.uri, new_date.uri)
        end
      end
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
    def upload(data, blueprint, dataset_name, options = {})
      GoodData::Model.upload_data(data, blueprint, dataset_name, options.merge(client: client, project: self))
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
    def users(opts = { offset: 0, limit: 1_000 })
      result = []

      # TODO: @korczis, review this after WA-3953 get fixed
      offset = 0 || opts[:offset]
      uri = "/gdc/projects/#{pid}/users?offset=#{offset}&limit=#{opts[:limit]}"
      loop do
        break unless uri
        tmp = client(opts).get(uri)
        tmp['users'].each do |user|
          result << client.factory.create(GoodData::Membership, user, project: self)
        end
        offset += opts[:limit]
        if tmp['users'].length == opts[:limit]
          uri = "/gdc/projects/#{pid}/users?offset=#{offset}&limit=#{opts[:limit]}"
        else
          uri = nil
        end
      end

      opts[:all] ? result : result.select(&:enabled?).reject(&:deleted?)
    end

    alias_method :members, :users

    def whitelist_users(new_users, users_list, whitelist)
      return [new_users, users_list] unless whitelist

      new_whitelist_proc = proc do |user|
        whitelist.any? { |wl| wl.is_a?(Regexp) ? user[:login] =~ wl : user[:login].include?(wl) }
      end

      whitelist_proc = proc do |user|
        whitelist.any? { |wl| wl.is_a?(Regexp) ? user.login =~ wl : user.login.include?(wl) }
      end

      [new_users.reject(&new_whitelist_proc), users_list.reject(&whitelist_proc)]
    end

    # Imports users
    def import_users(new_users, options = {})
      domain = options[:domain]
      role_list = roles
      users_list = users(all: true, offset: 0, limit: 1_000)
      new_users = new_users.map { |x| (x.is_a?(Hash) && x[:user] && x[:user].to_hash.merge(role: x[:role])) || x.to_hash }

      GoodData.logger.warn("Importing users to project (#{pid})")

      whitelisted_new_users, whitelisted_users = whitelist_users(new_users.map(&:to_hash), users_list, options[:whitelists])

      # conform the role on list of new users so we can diff them with the users coming from the project
      diffable_new_with_default_role = whitelisted_new_users.map do |u|
        u[:role] = Array(u[:role] || u[:roles] || 'readOnlyUser')
        u
      end

      diffable_new = diffable_new_with_default_role.map do |u|
        u[:role] = u[:role].map do |r|
          role = get_role(r, role_list)
          role && role.uri
        end
        u[:status] = 'ENABLED'
        u
      end

      # Diff users. Only login and role is important for the diff
      diff = GoodData::Helpers.diff(whitelisted_users, diffable_new, key: :login, fields: [:login, :role, :status])

      results = []
      # Create new users
      u = diff[:added].map do |x|
        {
          user: x,
          role: x[:role]
        }
      end
      # This is only creating users that were not in the proejcts so far. This means this will reach into domain
      GoodData.logger.warn("Creating #{diff[:added].count} users in project (#{pid})")
      results.concat create_users(u, roles: role_list, domain: domain, project_users: whitelisted_users, only_domain: true)

      # # Update existing users
      GoodData.logger.warn("Updating #{diff[:changed].count} users in project (#{pid})")
      list = diff[:changed].map { |x| { user: x[:new_obj], role: x[:new_obj][:role] || x[:new_obj][:roles] } }
      results.concat(set_users_roles(list, roles: role_list, project_users: whitelisted_users))

      # Remove old users
      to_remove = diff[:removed].reject { |user| user[:status] == 'DISABLED' || user[:status] == :disabled }
      GoodData.logger.warn("Removing #{to_remove.count} users in project (#{pid})")
      results.concat(disable_users(to_remove))
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

    def verify_user_to_add(login, desired_roles, options = {})
      user = login if login.respond_to?(:uri) && !login.uri.nil?
      role_list = options[:roles] || roles
      desired_roles = Array(desired_roles)
      roles = desired_roles.map do |role_name|
        role = get_role(role_name, role_list)
        fail ArgumentError, "Invalid role '#{role_name}' specified for user '#{user.email}'" if role.nil?
        role.uri
      end
      return [user.uri, roles] if user

      domain = client.domain(options[:domain]) if options[:domain]
      domain_users = options[:domain_users] || (domain && domain.users)
      project_users = options[:project_users] || users

      project_user = get_user(login, project_users)
      domain_user = if domain && !project_user && !user
                      domain.get_user(login, domain_users) if domain && !project_user
                    end
      user = project_user || domain_user
      fail ArgumentError, "Invalid user '#{login}' specified" unless user
      [user.uri, roles]
    end

    # Update user
    #
    # @param user User to be updated
    # @param desired_roles Roles to be assigned to user
    # @param role_list Optional cached list of roles used for lookups
    def set_user_roles(login, desired_roles, options = {})
      user_uri, roles = verify_user_to_add(login, desired_roles, options)
      url = "#{uri}/users"
      payload = generate_user_payload(user_uri, 'ENABLED', roles)
      client.post(url, payload)
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
      domain = options[:domain] && client.domain(options[:domain])
      domain_users = if domain.nil?
                       options[:domain_users]
                     else
                       if options[:only_domain] && list.count < 100
                         list.map { |l| domain.find_user_by_login(l[:user][:login]) }
                       else
                         domain.users
                       end
                     end

      users_to_add = list.flat_map do |user_hash|
        user = user_hash[:user] || user_hash[:login]
        desired_roles = user_hash[:role] || user_hash[:roles] || 'readOnlyUser'
        begin
          login, roles = verify_user_to_add(user, desired_roles, options.merge(domain_users: domain_users, project_users: project_users, roles: role_list))
          [{ login: login, roles: roles }]
        rescue
          []
        end
      end
      payloads = users_to_add.map { |u| generate_user_payload(u[:login], 'ENABLED', u[:roles]) }
      url = "#{uri}/users"
      results = payloads.each_slice(100).map do |payload|
        client.post(url, 'users' => payload)
      end
      results.flat_map { |x| x['projectUsersUpdateResult'].flat_map { |k, v| v.map { |v_2| { type: k.to_sym, uri: v_2 } } } }
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
