# encoding: UTF-8

require 'zip'
require 'fileutils'

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
      def [](id)
        return id if id.respond_to?(:project?) && id.project?
        if id == :all
          Project.all
        else
          if id.to_s !~ /^(\/gdc\/(projects|md)\/)?[a-zA-Z\d]+$/
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

        json = { 'project' =>
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

    def add_dashboard(options = {})
      dash = GoodData::Dashboard.create(options)
      dash.save
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

    def add_user(email_address, domain)
      fail 'Not implemented'
    end

    def browser_uri(options = {})
      grey = options[:grey]
      if grey
        GoodData.connection.url + uri
      else
        GoodData.connection.url + '#s=' + uri
      end
    end

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

    # Gets project role by its identifier
    #
    # @param role_name [String] Title of role to look for
    def get_role_by_identifier(role_name)
      tmp = roles
      tmp.each do |role|
        return role if role.identifier.downcase == role_name.downcase
      end
      return nil
    end

    # Gets project role byt its summary
    #
    # @param role_summary [String] Summary of role to look for
    def get_role_by_summary(role_summary)
      tmp = roles
      tmp.each do |role|
        return role if role.summary.downcase == role_summary.downcase
      end
      return nil
    end

    # Gets project role by its name
    #
    # @param role_title [String] Title of role to look for
    def get_role_by_title(role_title)
      tmp = roles
      tmp.each do |role|
        return role if role.title.downcase == role_title.downcase
      end
      return nil
    end

    # Initializes object instance from raw wire JSON
    #
    # @param json Json used for initialization
    def initialize(json)
      @json = json
    end

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
        :invitations => [{
                           :invitation => {
                             :content => {
                               :email => email,
                               :role => role_url,
                               :action => {
                                 :setMessage => msg
                               }
                             }
                           }
                         }]
      }

      url = "/gdc/projects/#{self.pid}/invitations"
      GoodData.post(url, data)
    end

    def links
      data['links']
    end

    def md
      @md ||= Links.new GoodData.get(data['links']['metadata'])
    end

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
      polling_result = GoodData.get(polling_url)

      while polling_result['wTaskStatus']['status'] == 'RUNNING'
        sleep(3)
        polling_result = GoodData.get(polling_url)
      end
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
      polling_result = GoodData.get(polling_url)
      while polling_result['wTaskStatus']['status'] == 'RUNNING'
        sleep(3)
        polling_result = GoodData.get(polling_url)
      end
      fail 'Exporting objects failed' if polling_result['wTaskStatus']['status'] == 'ERROR'
    end

    alias_method :transfer_objects, :partial_md_export

    def project?
      true
    end

    def reload!
      if saved?
        response = GoodData.get(uri)
        @json = response
      end
      self
    end

    def roles
      url = "/gdc/projects/#{self.pid}/roles"

      res = []

      tmp = GoodData.get(url)
      tmp['projectRoles']['roles'].each do |role_url|
        json = GoodData.get role_url
        res << GoodData::ProjectRole.new(json)
      end

      return res
    end

    def save
      response = GoodData.post PROJECTS_PATH, raw_data
      if uri.nil?
        response = GoodData.get response['uri']
        @json = response
      end
    end

    def saved?
      !uri.nil?
    end

    def slis
      link = "#{data['links']['metadata']}#{SLIS_PATH}"

      # TODO: Review what to do with passed extra argument
      Metadata.new GoodData.get(link)
    end

    def state
      data['content']['state'].downcase.to_sym if data['content'] && data['content']['state']
    end

    def title
      data['meta']['title'] if data['meta']
    end

    def upload(file, schema, mode = 'FULL')
      schema.upload file, self, mode
    end

    def uri
      data['links']['self'] if data && data['links'] && data['links']['self']
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
