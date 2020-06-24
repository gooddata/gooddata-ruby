# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'csv'
require 'zip'
require 'fileutils'
require 'multi_json'
require 'pmap'
require 'zip'
require 'net/smtp'

require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/compact'
require 'active_support/core_ext/hash/slice'

require_relative '../exceptions/no_project_error'

require_relative '../helpers/auth_helpers'

require_relative '../rest/resource'
require_relative '../mixins/author'
require_relative '../mixins/contributor'
require_relative '../mixins/rest_resource'
require_relative '../mixins/uri_getter'

require_relative 'membership'
require_relative 'process'
require_relative 'project_log_formatter'
require_relative 'project_role'
require_relative 'blueprint/blueprint'

require_relative 'metadata/scheduled_mail'
require_relative 'metadata/scheduled_mail/dashboard_attachment'
require_relative 'metadata/scheduled_mail/report_attachment'

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
      def all(opts = { client: GoodData.connection }, limit = nil, offset = nil)
        c = GoodData.get_client(opts)
        c.user.projects(limit, offset)
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
          fail(ArgumentError, 'wrong type of argument. Should be either project ID or path') unless project_id_or_path?(id)

          id = id.match(/[a-zA-Z\d]+$/)[0] if id =~ %r{/}

          c = GoodData.get_client(opts)
          response = c.get(PROJECT_PATH % id)
          c.factory.create(Project, response)
        end
      end

      def project_id_or_path?(id)
        id.to_s =~ %r{^(\/gdc\/(projects|md)\/)?[a-zA-Z\d]+$}
      end

      # Clones project along with etl and schedules
      #
      # @param project [Project] Project to be cloned from
      # @param [options] Options that are passed into project.clone
      # @return [GoodData::Project] New cloned project
      def clone_with_etl(project, options = {})
        a_clone = project.clone(options)
        GoodData::Project.transfer_etl(project.client, project, a_clone)
        a_clone
      end

      def create_object(data = {})
        c = GoodData.get_client(data)
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
      def create(opts = { client: GoodData.connection }, &block)
        GoodData.logger.info "Creating project #{opts[:title]}"

        auth_token = opts[:auth_token] || opts[:token]
        if auth_token.nil? || auth_token.empty?
          opts = { auth_token: Helpers::AuthHelper.read_token }.merge(opts)
          auth_token = opts[:auth_token]
        end
        fail ArgumentError, 'You have to provide your token for creating projects as :auth_token or :token parameter' if auth_token.nil? || auth_token.empty?

        project = create_object(opts)
        project.save
        # until it is enabled or deleted, recur. This should still end if there
        # is a exception thrown out from RESTClient. This sometimes happens from
        # WebApp when request is too long
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

      def find(opts = { client: GoodData.connection })
        c = GoodData.get_client(opts)
        user = c.user
        user.projects['projects'].map do |project|
          c.create(GoodData::Project, project)
        end
      end

      def create_from_blueprint(blueprint, options = {})
        GoodData::Model::ProjectCreator.migrate(options.merge(spec: blueprint, client: client))
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

      def transfer_output_stage(from_project, to_project, options)
        from_prj_output_stage = from_project.add.output_stage
        output_stage_prefix = options[:ads_output_stage_prefix] || from_prj_output_stage.output_stage_prefix
        output_stage_uri = options[:ads_output_stage_uri] || from_prj_output_stage.schema
        if from_project.processes.any? { |p| p.type == :dataload }
          if to_project.processes.any? { |p| p.type == :dataload }
            to_project.add.output_stage.schema = output_stage_uri
            to_project.add.output_stage.output_stage_prefix = output_stage_prefix
            to_project.add.output_stage.save
          else
            from_server = from_project.client.connection.server.url
            to_server = to_project.client.connection.server.url
            if from_server != to_server && options[:ads_output_stage_uri].nil?
              raise "Cannot transfer output stage from #{from_server} to #{to_server}. " \
                    'It is not possible to transfer output stages between ' \
                    'different domains. Please specify an address of an output ' \
                    'stage that is in the same domain as the target project ' \
                    'using the "ads_output_stage_uri" parameter.'
            end

            to_project.add.output_stage = GoodData::AdsOutputStage.create(
              client: to_project.client,
              ads: output_stage_uri,
              client_id: from_prj_output_stage.client_id,
              output_stage_prefix: output_stage_prefix,
              project: to_project
            )
          end
        end
      end

      # Clones project along with etl and schedules.
      #
      # @param client [GoodData::Rest::Client] GoodData client to be used for connection
      # @param from_project [GoodData::Project | GoodData::Segment | GoodData:Client | String]
      # Object to be cloned from. Can be either segment in which case we
      # take the master, client in which case we take its project, string
      # in which case we treat is as an project object or directly project
      # @param to_project [GoodData::Project | GoodData::Segment | GoodData:Client | String]
      def transfer_etl(client, from_project, to_project)
        from_project = case from_project
                       when GoodData::Client
                         from_project.project
                       when GoodData::Segment
                         from_project.master_project
                       else
                         client.projects(from_project)
                       end

        to_project = case to_project
                     when GoodData::Client
                       to_project.project
                     when GoodData::Segment
                       to_project.master_project
                     else
                       client.projects(to_project)
                     end
        transfer_processes(from_project, to_project)
        transfer_schedules(from_project, to_project)
      end

      # @param from_project The source project
      # @param to_project The target project
      # @param options Optional parameters
      # @option ads_output_stage_uri Uri of the source output stage. It must be in the same domain as the target project.
      def transfer_processes(from_project, to_project, options = {})
        options = GoodData::Helpers.symbolize_keys(options)
        to_project_processes = to_project.processes
        additional_hidden_params = options[:additional_hidden_params] || {}
        result = from_project.processes.uniq(&:name).map do |process|
          fail "The process name #{process.name} must be unique in transfered project #{to_project}" if to_project_processes.count { |p| p.name == process.name } > 1
          next if process.type == :dataload || process.add_v2_component?

          to_process = to_project_processes.find { |p| p.name == process.name }

          to_process = if process.path
                         to_process.delete if to_process
                         GoodData::Process.deploy_from_appstore(process.path, name: process.name, client: to_project.client, project: to_project)
                       elsif process.component
                         to_process.delete if to_process
                         process_hash = GoodData::Helpers::DeepMergeableHash[GoodData::Helpers.symbolize_keys(process.to_hash)].deep_merge(additional_hidden_params)
                         GoodData::Process.deploy_component(process_hash, project: to_project, client: to_project.client)
                       else
                         Dir.mktmpdir('etl_transfer') do |dir|
                           dir = Pathname(dir)
                           filename = dir + 'process.zip'
                           File.open(filename, 'w') do |f|
                             f << process.download
                           end

                           if to_process
                             to_process.deploy(filename, type: process.type, name: process.name)
                           else
                             to_project.deploy_process(filename, type: process.type, name: process.name)
                           end
                         end
                       end

          {
            from: from_project.pid,
            to: to_project.pid,
            name: process.name,
            status: to_process ? 'successful' : 'failed'
          }
        end

        transfer_output_stage(from_project, to_project, options)
        result << {
          from: from_project.pid,
          to: to_project.pid,
          name: 'Automated Data Distribution',
          status: 'successful'
        }

        res = (from_project.processes + to_project.processes).map { |p| [p, p.name, p.type] }
        res.group_by { |x| [x[1], x[2]] }
          .select { |_, procs| procs.length == 1 && procs[2] != :dataload }
          .reject { |_, procs| procs.first.first.add_v2_component? }
          .flat_map { |_, procs| procs.select { |p| p[0].project.pid == to_project.pid }.map { |p| p[0] } }
          .peach(&:delete)

        result.compact
      end

      def transfer_user_groups(from_project, to_project)
        from_project.user_groups.map do |ug|
          # migrate groups
          new_group = to_project.user_groups.select { |group| group.name == ug.name }.first
          new_group_status = new_group ? 'modified' : 'created'
          new_group ||= UserGroup.create(:name => ug.name, :description => ug.description, :project => to_project)
          new_group.project = to_project
          new_group.description = ug.description
          new_group.save
          # migrate dashboard "grantees"
          dashboards = from_project.dashboards
          dashboards.each do |dashboard|
            new_dashboard = to_project.dashboards.select { |dash| dash.title == dashboard.title }.first
            next unless new_dashboard
            grantee = dashboard.grantees['granteeURIs']['items'].select { |item| item['aclEntryURI']['grantee'].split('/').last == ug.links['self'].split('/').last }.first
            next unless grantee
            permission = grantee['aclEntryURI']['permission']
            new_dashboard.grant(:member => new_group, :permission => permission)
          end

          {
            from: from_project.pid,
            to: to_project.pid,
            user_group: new_group.name,
            status: new_group_status
          }
        end
      end

      # Clones project along with etl and schedules.
      #
      # @param client [GoodData::Rest::Client] GoodData client to be used for connection
      # @param from_project [GoodData::Project | GoodData::Segment | GoodData:Client | String]
      # Object to be cloned from. Can be either segment in which case we take
      # the master, client in which case we take its project, string in which
      # case we treat is as an project object or directly project.
      def transfer_schedules(from_project, to_project)
        to_project_processes = to_project.processes.sort_by(&:name)
        from_project_processes = from_project.processes.sort_by(&:name)
        from_project_processes.reject!(&:add_v2_component?)

        GoodData.logger.debug("Processes in from project #{from_project.pid}: #{from_project_processes.map(&:name).join(', ')}")
        GoodData.logger.debug("Processes in to project #{to_project.pid}: #{to_project_processes.map(&:name).join(', ')}")

        cache = to_project_processes
                  .zip(from_project_processes)
                  .flat_map do |remote, local|
                    local.schedules.map do |schedule|
                      [remote, local, schedule]
                    end
                  end

        remote_schedules = to_project.schedules
        remote_stuff = remote_schedules.map do |s|
          v = s.to_hash
          after_schedule = remote_schedules.find { |s2| s.trigger_id == s2.obj_id }
          v[:after] = s.trigger_id && after_schedule && after_schedule.name
          v[:remote_schedule] = s
          v[:params] = v[:params].except("EXECUTABLE", "PROCESS_ID")
          v.compact
        end

        local_schedules = from_project.schedules
        local_stuff = local_schedules.map do |s|
          v = s.to_hash
          after_schedule = local_schedules.find { |s2| s.trigger_id == s2.obj_id }
          v[:after] = s.trigger_id && after_schedule && after_schedule.name
          v[:remote_schedule] = s
          v[:params] = v[:params].except("EXECUTABLE", "PROCESS_ID")
          v.compact
        end

        diff = GoodData::Helpers.diff(remote_stuff, local_stuff, key: :name, fields: [:name, :cron, :after, :params, :hidden_params, :reschedule, :state])
        stack = diff[:added].map do |x|
          [:added, x]
        end

        stack += diff[:changed].map do |x|
          [:changed, x]
        end

        schedule_cache = remote_schedules.reduce({}) do |a, e|
          a[e.name] = e
          a
        end

        results = []
        loop do # rubocop:disable Metrics/BlockLength
          break if stack.empty?
          state, changed_schedule = stack.shift
          if state == :added
            schedule_spec = changed_schedule
            if schedule_spec[:after] && !schedule_cache[schedule_spec[:after]]
              stack << [state, schedule_spec]
              next
            end
            remote_process, process_spec = cache.find do |_remote, local, schedule|
              (schedule_spec[:process_id] == local.process_id) && (schedule.name == schedule_spec[:name])
            end

            next unless remote_process || process_spec

            GoodData.logger.info("Creating schedule #{schedule_spec[:name]} for process #{remote_process.name}")

            executable = nil
            if process_spec.type != :dataload
              executable = schedule_spec[:executable] || (process_spec.type == :ruby ? 'main.rb' : 'main.grf')
            end
            params = schedule_parameters(schedule_spec)
            created_schedule = remote_process.create_schedule(schedule_spec[:cron] || schedule_cache[schedule_spec[:after]], executable, params)
            schedule_cache[created_schedule.name] = created_schedule

            results << {
              state: :added,
              process: remote_process,
              schedule: created_schedule
            }
          else
            schedule_spec = changed_schedule[:new_obj]
            if schedule_spec[:after] && !schedule_cache[schedule_spec[:after]]
              stack << [state, schedule_spec]
              next
            end

            remote_process, process_spec = cache.find do |i|
              i[2].name == schedule_spec[:name]
            end

            schedule = changed_schedule[:old_obj][:remote_schedule]

            GoodData.logger.info("Updating schedule #{schedule_spec[:name]} for process #{remote_process.name}")

            schedule.params = (schedule_spec[:params] || {})
            schedule.cron = schedule_spec[:cron] if schedule_spec[:cron]
            schedule.after = schedule_cache[schedule_spec[:after]] if schedule_spec[:after]
            schedule.hidden_params = schedule_spec[:hidden_params] || {}
            if process_spec.type != :dataload
              schedule.executable = schedule_spec[:executable] || (process_spec.type == :ruby ? 'main.rb' : 'main.grf')
            end

            schedule.reschedule = schedule_spec[:reschedule]
            schedule.name = schedule_spec[:name]
            schedule.state = schedule_spec[:state]
            schedule.save
            schedule_cache[schedule.name] = schedule

            results << {
              state: :changed,
              process: remote_process,
              schedule: schedule
            }
          end
        end

        diff[:removed].each do |removed_schedule|
          GoodData.logger.info("Removing schedule #{removed_schedule[:name]}")

          removed_schedule[:remote_schedule].delete

          results << {
            state: :removed,
            process: removed_schedule.process,
            schedule: removed_schedule
          }
        end

        results
      end

      def transfer_tagged_stuff(from_project, to_project, tag)
        GoodData.logger.info("Transferring tagged stuff - #{tag}")

        objects = from_project.find_by_tag(tag)

        if objects.any?
          GoodData.logger.info("\n#{JSON.pretty_generate(objects)}")
          from_project.partial_md_export(objects, project: to_project)
        else
          GoodData.logger.info('No tagged objects to transfer')
        end
      end

      def transfer_color_palette(from_project, to_project)
        colors = from_project.current_color_palette
        to_project.create_custom_color_palette(colors) unless colors.empty?
      end

      private

      def schedule_parameters(schedule_spec)
        {
          params: schedule_spec[:params],
          hidden_params: schedule_spec[:hidden_params],
          name: schedule_spec[:name],
          reschedule: schedule_spec[:reschedule],
          state: schedule_spec[:state]
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
      report = GoodData::Report.create(options.merge(client: client, project: self))
      report.save
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

    def computed_attributes(id = :all)
      attrs = attributes(id)
      if attrs.is_a?(GoodData::Attribute)
        attrs.computed_attribute? ? attrs : nil
      else
        attrs.select(&:computed_attribute?)
      end
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
      options = { include_ca: true }.merge(options)
      result = client.get("/gdc/projects/#{pid}/model/view", params: { includeDeprecated: true, includeGrain: true, includeCA: options[:include_ca] })

      polling_url = result['asyncTask']['link']['poll']
      model = client.poll_on_code(polling_url, options)
      bp = GoodData::Model::FromWire.from_wire(model, options)
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
    # @option options [Boolean] :exclude_schedules Specifies whether to include scheduled emails
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
    # @option options [Boolean] :exclude_schedules Specifies whether to include scheduled notifications in the export
    # @option options [Boolean] :cross_data_center_export Specifies whether export can be used in any data center
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
      if options[:exclude_schedules]
        exclude_notifications = options[:exclude_schedules] ? 1 : 0
        export[:exportProject][:excludeSchedules] = exclude_notifications
      end
      if options[:cross_data_center_export]
        cross_data_center = options[:cross_data_center_export] ? 1 : 0
        export[:exportProject][:crossDataCenterExport] = cross_data_center
      end

      result = client.post("/gdc/md/#{obj_id}/maintenance/export", export)
      status_url = result['exportArtifact']['status']['uri']
      polling_result = client.poll_on_response(status_url) do |body|
        body['taskState']['status'] == 'RUNNING'
      end

      ensure_clone_task_ok(polling_result, GoodData::ExportCloneError)
      result['exportArtifact']['token']
    end

    def folders(id = :all)
      GoodData::Folder[id, project: self, client: client]
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
      polling_result = client.poll_on_response(status_url, options) do |body|
        body['taskState']['status'] == 'RUNNING'
      end
      ensure_clone_task_ok(polling_result, GoodData::ImportCloneError)
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
    alias_method :user_filters, :data_permissions

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
      begin
        datasets.reject(&:date_dimension?).pmap(&:delete_data)
      rescue MaqlExecutionError => e
        # This is here so that we do not throw out exceptions on synchornizing date dimensions
        # Currently there is no reliable way how to tell it is a date dimension
        fail e unless GoodData::Helpers.interpolate_error_messages(e.data['wTaskStatus']['messages']) == ["Internal error [handle_exception, hide_internal]."]
      end
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

      result = client.poll_on_response(polling_uri, options) do |body|
        body && body['wTaskStatus'] && body['wTaskStatus']['status'] == 'RUNNING'
      end
      if result['wTaskStatus']['status'] == 'ERROR'
        fail MaqlExecutionError.new("Executionof MAQL '#{maql}' failed in project '#{pid}'", result)
      end
      result
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

    def driver
      content['driver']
    end

    def environment
      content['environment']
    end

    def public?
      content['isPublic']
    end

    def token
      content['authorizationToken']
    end

    # Gets user by its email, full_name, login or uri
    alias_method :member, :get_user

    def find_by_tag(tags)
      tags = tags.split(',').map(&:strip) unless tags.is_a?(Array)

      objects = tags.map do |tag|
        url = "/gdc/md/#{pid}/tags/#{tag}"
        res = client.get(url)

        ((res || {})['entries'] || []).map do |entry|
          entry['link']
        end
      end

      objects.flatten!

      objects.uniq!

      objects
    end

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
      @log_formatter = GoodData::ProjectLogFormatter.new(self)
    end

    # Invites new user to project
    #
    # @param email [String] User to be invited
    # @param role [String] Role URL or Role ID to be used
    # @param msg [String] Optional invite message
    #
    # TODO: Return invite object
    def invite(email, role, msg = DEFAULT_INVITE_MESSAGE)
      GoodData.logger.info("Inviting #{email}, role: #{role}")

      role_url = nil
      if role.index('/gdc/').nil?
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
      GoodData::ProjectMetadata.[]=(key, { client: client, project: self }, val)
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
      objs = Array(objs).map { |o| o.respond_to?(:uri) ? o.uri : o }
      if objs.empty?
        GoodData.logger.warn 'Nothing to migrate.'
        return
      end

      export_payload = {
        :partialMDExport => {
          :uris => objs,
          :exportAttributeProperties => '1',
          :crossDataCenterExport => '1'
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
          :updateLDMObjects => '1',
          :importAttributeProperties => '1'
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
    # @return [Boolean | Array<Hash>] Return either true or throws exception
    # if you passed only one project. If you provided an array returns list
    # of hashes signifying sucees or failure. Take note that in case of list
    # of projects it does not throw exception.
    def partial_md_export(objects, options = {})
      projects = options[:project]
      batch_size = options[:batch_size] || 10
      token = objects_export(objects)
      return if token.nil?

      if projects.is_a?(Array)
        projects.each_slice(batch_size).flat_map do |batch|
          batch.pmap do |proj|
            target_project = client.projects(proj)
            target_project.objects_import(token, options)
            {
              project: target_project,
              result: true
            }
          end
        end
      else
        target_project = client.projects(projects)
        target_project.objects_import(token, options)
        [{
          project: target_project,
          result: true
        }]
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
      GoodData.logger.info(title)
      GoodData.logger.info(GoodData::Helpers.underline(title))
      GoodData.logger.info("\nDatasets - #{results.count}\n")
      results.each do |x|
        dataset, count = x
        dataset.title.tap do |t|
          GoodData.logger.info(t)
          GoodData.logger.info(GoodData::Helpers.underline(t))
          GoodData.logger.info("Size - #{count} rows")
          GoodData.logger.info("#{dataset.attributes_and_anchors.count} attributes, #{dataset.facts.count} facts, #{dataset.references.count} references\n")
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

    # Method used for walking through objects in project and trying to
    # replace all occurences of some object for another object. This is
    # typically used as a means for exchanging Date dimensions.
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
        GoodData.logger.info("Replacing #{key}")
        collection.peach do |item|
          new_item = item.replace(mapping)
          if new_item.json != item.json
            if dry_run
              GoodData.logger.info "Would save #{new_item.uri}. Running in dry run mode"
            else
              GoodData.logger.info "Saving #{new_item.uri}"
              new_item.save
            end
          else
            GoodData.logger.info "Ignore #{item.uri}"
          end
        end
      end

      GoodData.logger.info 'Replacing hidden metrics'
      local_metrics = mapping.map { |a, _| a }.pmapcat { |a| a.usedby('metric') }.select { |m| m['deprecated'] == '1' }.map { |m| m['link'] }.uniq
      GoodData.logger.info("Found #{local_metrics.count} metrics")
      local_metrics.pmap { |m| metrics(m) }.peach do |item|
        new_item = item.replace(mapping)
        if new_item.json != item.json
          if dry_run
            GoodData.logger.info "Would save #{new_item.uri}. Running in dry run mode"
          else
            GoodData.logger.info "Saving #{new_item.uri}"
            new_item.save
          end
        else
          GoodData.logger.info "Ignore #{item.uri}"
        end
      end

      GoodData.logger.info 'Replacing dashboard saved views'
      contexts = mapping.map { |a, _| a }.pmapcat { |a| a.usedby('executionContext') }.map { |a| GoodData::MdObject[a['link'], client: client, project: self] }
      GoodData.logger.info("Found #{contexts.count} dashboard saved views")
      contexts.peach do |item|
        new_item = GoodData::MdObject.replace_quoted(item, mapping)
        if new_item.json != item.json
          if dry_run
            GoodData.logger.info "Would save #{new_item.uri}. Running in dry run mode"
          else
            GoodData.logger.info "Saving #{new_item.uri}"
            new_item.save
          end
        else
          GoodData.logger.info "Ignore #{item.uri}"
        end
      end

      GoodData.logger.info 'Replacing variable values'
      variables.each do |var|
        var.values.peach do |val|
          val.replace(mapping).save unless dry_run
        end
      end

      {
        visualizations: MdObject.query('visualizationObject', MdObject, client: client, project: self),
        visualization_widgets: MdObject.query('visualizationWidget', MdObject, client: client, project: self),
        kpis: MdObject.query('kpi', MdObject, client: client, project: self)
      }.each do |key, collection|
        GoodData.logger.info "Replacing #{key}"
        collection.each do |item|
          new_item = MdObject.replace_quoted(item, mapping)
          if new_item.json != item.json
            if dry_run
              GoodData.logger.info "Would save #{new_item.uri}. Running in dry run mode"
            else
              GoodData.logger.info "Saving #{new_item.uri}"
              new_item.save
            end
          else
            GoodData.logger.info "Ignore #{item.uri}"
          end
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
      url = "/gdc/internal/projects/#{pid}/roles"
      res = client.get url
      res['internalProjectRoles']['roles'].map do |r|
        client.create(GoodData::ProjectRole, r, project: self)
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

    # Schedules an email with dashboard or report content
    def schedule_mail(options = GoodData::ScheduledMail::DEFAULT_OPTS)
      GoodData::ScheduledMail.create(options.merge(client: client, project: self))
    end

    def scheduled_mails(options = { :full => false })
      GoodData::ScheduledMail[:all, options.merge(project: self, client: client)]
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

    # List of users in project
    #
    #
    # @return [Array<GoodData::User>] List of users
    def users(opts = {})
      client = client(opts)
      all_users = []
      offset = opts[:offset] || 0
      limit = opts[:limit] || 1_000
      loop do
        tmp = client.get("/gdc/projects/#{pid}/users", params: { offset: offset, limit: limit })
        tmp['users'].each do |user_data|
          user = client.create(GoodData::Membership, user_data, project: self)

          if opts[:all]
            all_users << user
          elsif opts[:disabled]
            all_users << user if user&.disabled?
          else
            all_users << user if user&.enabled?
          end
        end
        break if tmp['users'].count < limit

        offset += limit
      end

      all_users
    end

    alias_method :members, :users

    def whitelist_users(new_users, users_list, whitelist, mode = :exclude)
      return [new_users, users_list] unless whitelist

      new_whitelist_proc = proc do |user|
        whitelist.any? do |wl|
          if wl.is_a?(Regexp)
            user[:login] =~ wl
          else
            user[:login] && user[:login] == wl
          end
        end
      end

      whitelist_proc = proc do |user|
        whitelist.any? do |wl|
          if wl.is_a?(Regexp)
            user.login =~ wl
          else
            user.login && user.login == wl
          end
        end
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
      users_list = users

      GoodData.logger.warn("Importing users to project (#{pid})")
      new_users = new_users.map { |x| ((x.is_a?(Hash) && x[:user] && x[:user].to_hash.merge(role: x[:role])) || x.to_hash).tap { |u| u[:login].downcase! } }
      # First check that if groups are provided we have them set up
      user_groups_cache, change_groups = check_groups(new_users.map(&:to_hash).flat_map { |u| u[:user_group] || [] }.uniq, options[:user_groups_cache], options)

      unless change_groups.empty?
        new_users.each do |user|
          user[:user_group].map! { |e| change_groups[e].nil? ? e : change_groups[e] }
        end
      end

      whitelisted_new_users, whitelisted_users = whitelist_users(new_users.map(&:to_hash), users_list, options[:whitelists])

      # conform the role on list of new users so we can diff them with the users coming from the project
      diffable_new_with_default_role = whitelisted_new_users.map do |u|
        u[:role] = Array(u[:role] || u[:roles] || 'readOnlyUser')
        u
      end

      intermediate_new = diffable_new_with_default_role.map do |u|
        u[:role] = u[:role].map do |r|
          role = get_role(r, role_list)
          role ? role.uri : r
        end

        u[:role_title] = u[:role].map do |r|
          role = get_role(r, role_list)
          role ? role.title : r
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
      diff_results = diff.flat_map do |operation, users|
        if operation == :changed
          users.map { |u| u[:new_obj].merge(operation: operation) }
        else
          users.map { |u| u.merge(operation: operation) }
        end
      end
      diff_results = diff_results.map do |u|
        u[:login_uri] = "/gdc/account/profile/" + u[:login]
        u
      end
      return diff_results if options[:dry_run]

      # Create new users
      results = []
      GoodData.logger.warn("Creating #{diff[:added].count} users in project (#{pid})")
      to_create = diff[:added].map { |x| { user: x, role: x[:role] } }
      created_users_result = create_users(to_create, roles: role_list, project_users: whitelisted_users)
      @log_formatter.log_created_users(created_users_result, diff[:added])
      results.concat(created_users_result)
      send_mail_to_new_users(diff[:added], options[:email_options]) if options[:email_options] && !options[:email_options].empty? && !diff[:added].empty?

      # # Update existing users
      GoodData.logger.warn("Updating #{diff[:changed].count} users in project (#{pid})")
      to_update = diff[:changed].map { |x| { user: x[:new_obj], role: x[:new_obj][:role] || x[:new_obj][:roles] } }
      updated_users_result = set_users_roles(to_update, roles: role_list, project_users: whitelisted_users)
      @log_formatter.log_updated_users(updated_users_result, diff[:changed], role_list)
      results.concat(updated_users_result)

      unless options[:do_not_touch_users_that_are_not_mentioned]
        # Remove old users
        to_disable = diff[:removed].reject { |user| user[:status] == 'DISABLED' || user[:status] == :disabled }
        GoodData.logger.warn("Disabling #{to_disable.count} users from project (#{pid})")
        disabled_users_result = disable_users(to_disable, roles: role_list, project_users: whitelisted_users)
        @log_formatter.log_disabled_users(disabled_users_result)
        results.concat(disabled_users_result)

        # Remove old users completely
        if options[:remove_users_from_project]
          to_remove = (to_disable + users(disabled: true).to_a).map(&:to_hash).uniq do |user|
            user[:uri]
          end
          GoodData.logger.warn("Removing #{to_remove.count} users from project (#{pid})")
          removed_users_result = remove_users(to_remove)
          @log_formatter.log_removed_users(removed_users_result)
          results.concat(removed_users_result)
        end
      end

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
          remote_users = mapping.map { |user, _| user }.map { |login| users_lookup[login] && users_lookup[login].uri }.reject(&:nil?)
          GoodData.logger.info("Assigning users #{remote_users} to group #{g}")
          next if remote_users.empty?
          existing_group = user_groups(g)
          if existing_group.nil?
            GoodData.logger.warn("Group #{g} not found!!!")
          else
            existing_group.set_members(remote_users)
          end
        end
        mentioned_groups = mappings.map(&:last).uniq
        groups_to_cleanup = user_groups_cache.reject { |g| mentioned_groups.include?(g.name) }
        # clean all groups not mentioned with exception of whitelisted users
        groups_to_cleanup.each do |g|
          g.set_members(whitelist_users(g.members.map(&:to_hash), [], options[:whitelists], :include).first.map { |x| x[:uri] })
        end
      end
      GoodData::Helpers.join(results, diff_results, [:user], [:login_uri])
    end

    def disable_users(list, options = {})
      list = list.map(&:to_hash)
      url = "#{uri}/users"
      payloads = list.map do |u|
        uri, = resolve_roles(u, [], options)
        generate_user_payload(uri, 'DISABLED')
      end

      payloads.each_slice(100).mapcat do |payload|
        result = client.post(url, 'users' => payload)
        result['projectUsersUpdateResult'].mapcat { |k, v| v.map { |x| { type: k.to_sym, user: x } } }
      end
    end

    def remove_users(list)
      list = list.map(&:to_hash)

      list.pmapcat do |u|
        u_id = GoodData::Helpers.last_uri_part(u[:uri])
        url = "#{uri}/users/#{u_id}"
        begin
          client.delete(url)
          [{ type: :successful, operation: :user_deleted_from_project, user: u }]
        rescue => e
          [{ type: :failed, message: e.message, user: u }]
        end
      end
    end

    def check_groups(specified_groups, user_groups_cache = nil, options = {})
      current_user_groups = user_groups if user_groups_cache.nil? || user_groups_cache.empty?
      groups = current_user_groups.map(&:name)
      missing_groups = []
      change_groups = {}
      specified_groups.each do |group|
        found_group = groups.find { |name| name.casecmp(group).zero? }
        if found_group.nil?
          missing_groups << group
        else
          # Change groups when they have similar group name with difference of case sensitivity
          if found_group != group
            change_groups[group] = found_group
            GoodData.logger.warn("Group with name #{group} is existed in project with name #{found_group}.")
          end
        end
      end
      if options[:create_non_existing_user_groups]
        missing_groups.each do |g|
          GoodData.logger.info("Creating group #{g}")
          create_group(name: g, description: g)
        end
      else
        unless missing_groups.empty?
          fail 'All groups have to be specified before you try to import ' \
            'users. Groups that are currently in project are ' \
            "#{groups.join(',')} and you asked for #{missing_groups.join(',')}"
        end
      end
      [current_user_groups, change_groups]
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
      fail ArgumentError, "User #{user_uri} could not be added. #{failure.first['message']}" unless failure.blank?

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
          [{ :type => :failed, :reason => e.message, user: user, roles: desired_roles }]
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
      typed_results = results.flat_map do |x|
        x['projectUsersUpdateResult'].flat_map do |k, v|
          v.map { |v2| v2.is_a?(String) ? { type: k.to_sym, user: v2 } : GoodData::Helpers.symbolize_keys(v2).merge(type: k.to_sym) }
        end
      end
      # we have to concat errors from role resolution and API result
      typed_results + (users_by_type[:failed] || [])
    end

    alias_method :add_users, :set_users_roles
    alias_method :create_users, :set_users_roles

    def add_data_permissions(filters, options = {})
      GoodData.logger.info("Synchronizing #{filters.count} filters in project #{pid}")
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

    # Applies blueprint to the project.
    #
    # @param [Hash] blueprint Blueprint to apply to the project.
    # @option options [Hash] :update_preference (cascade_drops: false, preserve_data: true) Specifies how dropping LDM and data should be treated.
    # @example Update with custom update preference.
    #   GoodData.project.update_from_blueprint(
    #     blueprint,
    #     update_preference: {
    #       cascade_drops: false, preserve_data: false
    #     }
    #   )
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
        fail ArgumentError, "Invalid role '#{role_name}' specified for user '#{GoodData::Helpers.last_uri_part(user)}'" if role.nil?
        role.uri
      end
      [user, roles]
    end

    def upgrade_custom_v2(message, options = {})
      uri = "/gdc/md/#{pid}/datedimension/upgrade"
      poll_result = client&.post(uri, message)

      return poll_result['wTaskStatus']['status'] if poll_result['wTaskStatus'] && poll_result['wTaskStatus']['status']

      polling_uri = poll_result['asyncTask']['link']['poll']
      result = client&.poll_on_response(polling_uri, options) do |body|
        body && body['wTaskStatus'] && body['wTaskStatus']['status'] == 'RUNNING'
      end

      result['wTaskStatus']['status'] == 'OK' ? 'OK' : 'FAIL'
    end

    def add
      @add ||= GoodData::AutomatedDataDistribution.new(self)
      @add
    end

    def transfer_etl(target)
      GoodData::Project.transfer_etl(client, self, target)
    end

    def transfer_processes(target)
      GoodData::Project.transfer_processes(self, target)
    end

    def transfer_schedules(target)
      GoodData::Project.transfer_schedules(self, target)
    end

    def transfer_tagged_stuff(target, tag)
      GoodData::Project.transfer_tagged_stuff(self, target, tag)
    end

    def create_output_stage(ads, opts = {})
      add.create_output_stage(ads, opts)
    end

    def transfer_color_palette(target)
      GoodData::Project.transfer_color_palette(self, target)
    end

    def current_color_palette
      GoodData::StyleSetting.current(client: client, project: self)
    end

    def create_custom_color_palette(colors)
      GoodData::StyleSetting.create(colors, client: client, project: self)
    end

    def reset_color_palette
      GoodData::StyleSetting.reset(client: client, project: self)
    end

    # get maql diff from another project or blueprint to current project
    #
    # @param options [Hash] options
    # @option options [GoodData::Project] :project source project
    # @option options [GoodData::Model::ProjectBlueprint] :blueprint blueprint of source project
    # @option options [Array] :params additional parameters for diff api
    # @return [Hash] project model diff
    def maql_diff(options = {})
      fail "No :project or :blueprint specified" unless options[:blueprint] || options[:project]
      bp = options[:blueprint] || options[:project].blueprint
      uri = "/gdc/projects/#{pid}/model/diff"
      params = Hash[(options[:params] || []).map { |i| [i, true] }]
      result = client.post(uri, bp.to_wire, params: params)
      client.poll_on_code(result['asyncTask']['link']['poll'])
    end

    private

    def send_mail_to_new_users(users, email_options)
      password = email_options[:email_password]
      from = email_options[:email_from]
      raise 'Missing sender email, please specify parameter "email_from"' unless from
      raise 'Missing authentication password, please specify parameter "email_password"' unless password
      template = get_email_template(email_options)
      smtp = Net::SMTP.new('relay1.na.intgdc.com', 25)
      smtp.enable_starttls OpenSSL::SSL::SSLContext.new("TLSv1_2_client")
      smtp.start('notifications.gooddata.com', 'gdc', password, :plain)
      users.each do |user|
        smtp.send_mail(get_email_body(template, user), from, user[:login])
      end
    end

    def get_email_template(options)
      bucket = options[:email_template_bucket]
      path = options[:email_template_path]
      access_key = options[:email_template_access_key]
      secret_key = options[:email_template_secret_key]
      raise "Unable to connect to AWS. Parameter \"email_template_bucket\" seems to be empty" unless bucket
      raise "Unable to connect to AWS. Parameter \"email_template_path\" is missing" unless path
      raise "Unable to connect to AWS. Parameter \"email_template_access_key\" is missing" unless access_key
      raise "Unable to connect to AWS. Parameter \"email_template_secret_key\" is missing" unless secret_key
      args = {
        access_key_id: access_key,
        secret_access_key: secret_key,
        max_retries: 15,
        http_read_timeout: 120,
        http_open_timeout: 120
      }

      server_side_encryption = options['email_server_side_encryption'] || false
      args['s3_server_side_encryption'] = :aes256 if server_side_encryption

      s3 = Aws::S3::Resource.new(args)
      bucket = s3.bucket(bucket)
      process_email_template(bucket, path)
    end

    def process_email_template(bucket, path)
      type = path.split('/').last.include?('.html') ? 'html' : 'txt'
      body = bucket.object(path).read
      body.prepend("MIME-Version: 1.0\nContent-type: text/html\n") if type == 'html'
      body
    end

    def get_email_body(template, user)
      template.gsub('${name}', "#{user[:first_name]} #{user[:last_name]}")
              .gsub('${role}', user[:role_title].count == 1 ? user[:role_title].first : user[:role_title].to_s)
              .gsub('${user_group}', user[:user_group].count == 1 ? user[:user_group].first : user[:user_group].to_s)
              .gsub('${project}', Project[user[:pid]].title)
    end

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

    # Checks state of an export/import task.
    # @param response [Hash] Response from API
    # @param clone_task_error [Error] Error to raise when state is not OK
    def ensure_clone_task_ok(response, clone_task_error)
      if response['taskState'].nil?
        fail clone_task_error, "Clone task failed with unknown response: #{response}"
      elsif response['taskState']['status'] != 'OK'
        messages = response['taskState']['messages'] || []
        interpolated_messages = GoodData::Helpers.interpolate_error_messages(messages).join(' ')
        fail clone_task_error, "Clone task failed. #{interpolated_messages}"
      end
    end
  end
end
