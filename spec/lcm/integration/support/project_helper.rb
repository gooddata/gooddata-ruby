require 'gooddata'
require 'json'
require_relative 'constants'

module Support
  # Creates a testing project and loads it with data
  class ProjectHelper
    attr_reader :project, :client

    class << self
      def create(opts = { client: GoodData.connection })
        new_project = opts[:client].create_project(opts)
        ProjectHelper.new(new_project, opts)
      end
    end

    def initialize(project, opts = { client: GoodData.connection })
      @client = opts[:client]
      @project = project if project.instance_of? GoodData::Project
      @project = client.projects(project) if project.instance_of? String
      GoodData.logger.info "Project ID: #{@project.obj_id}"
      raise 'ProjectHelper::initialize the parameter "project" '\
            'must be GoodData::Project or String.' unless @project
    end

    def create_ldm(blueprint_path = BLUEPRINT_FILE)
      json = File.read(blueprint_path)
      blueprint = GoodData::Model::ProjectBlueprint.from_json(json)
      project.update_from_blueprint(blueprint)
    end

    def load_data(data_path = DATA_FILE, dataset_identifier = DATASET_IDENTIFIER)
      GoodData.with_project @project.pid do |project|
        GoodData::Model.upload_data(
          data_path,
          project.blueprint,
          dataset_identifier
        )
      end
    end

    def add_user_group
      @project.add_user_group(:name => USER_GROUP_NAME, :description => 'My Test Description')
    end

    def associate_output_stage(ads, opts = {})
      @project.create_output_stage(
        ads,
        project: @project,
        client: client,
        client_id: opts[:client_id],
        output_stage_prefix: opts[:output_stage_prefix]
      )
    end

    def deploy_processes(ads)
      GoodData.with_project @project.pid do |project|
        cc_process = project.deploy_process(
          CC_PROCESS_ARCHIVE,
          name: CC_PROCESS_NAME
        )
        cc_schedule = cc_process.create_schedule(
          CC_SCHEDULE_CRON,
          CC_GRAPH,
          params: CC_PARAMS,
          hidden_params: CC_SECURE_PARAMS,
          state: 'DISABLED'
        )
        ruby_process = project.deploy_process(
          RUBY_HELLO_WORLD_PROCESS_PATH,
          name: RUBY_HELLO_WORLD_PROCESS_NAME
        )
        ruby_schedule = ruby_process.create_schedule(
          cc_schedule,
          'main.rb',
          params: RUBY_PARAMS,
          hidden_params: RUBY_SECURE_PARAMS,
          state: 'DISABLED'
        )

        associate_output_stage ads
        add_process = project.add.process
        add_process.create_schedule(
          ruby_schedule,
          '',
          dataload_datasets: [ DATASET_IDENTIFIER ],
          de_synchronize_all: true,
          state: 'DISABLED'
        )
      end
    end

    def create_metrics
      GoodData.with_project @project.pid do |project|
        metrics = JSON.parse(File.read(METRICS_FILE)).to_hash
        metrics.each do |title, maql|
          metric = project.add_measure maql, title: title
          metric.identifier = "metric.#{title.to_s.downcase.gsub(/\s/, '.')}"
          metric.add_tag('metric') if metric.identifier == PRODUCTION_TAGGED_METRIC
          metric.save
        end
      end
    end

    def create_computed_attributes
      update = GoodData::Model::ProjectBlueprint.build('update') do |project_builder|
        project_builder.add_computed_attribute(
          COMPUTED_ATTRIBUTE_ID,
          title: 'My computed attribute',
          metric: 'metric.customers.count',
          attribute: 'attr.csv_policies.state',
          buckets: [{ label: 'Small', highest_value: 1000 }, { label: 'Medium', highest_value: 2000 }, { label: 'Large' }]
        )
      end
      new_blueprint = project.blueprint.merge(update)
      unless new_blueprint.valid?
        pp new_blueprint.validate
        raise 'Cannot create computed attribute'
      end
      project.update_from_blueprint(new_blueprint)

      project.attributes(COMPUTED_ATTRIBUTE_ID).drill_down(project.attributes('attr.csv_policies.customer'))
    end

    def create_reports
      GoodData.with_project @project.pid do |p|
        reports = JSON.parse(File.read(REPORTS_FILE)).to_hash['reports']
        reports.each do |r|
          report = p.add_report(
            title: r['title'],
            left: r['left'].map { |o| GoodData::MdObject[o] },
            top: r['top'].map { |o| GoodData::MdObject[o] }
          )
          report_name = r['title'].to_s.downcase.gsub(/\s/, '.')
          report.identifier = "report.#{report_name}"
          report.save
        end

        ca_report_title = 'Report contains CA'
        report = p.add_report(title: ca_report_title, left: GoodData::MdObject[COMPUTED_ATTRIBUTE_ID])
        report_name = ca_report_title.downcase.gsub(/\s/, '.')
        report.identifier = "report.#{report_name}"
        report.save
      end
    end

    def create_dashboards
      GoodData.with_project @project.pid do
        dashboards = JSON.parse(File.read(DASHBOARDS_FILE)).to_hash['dashboards']
        dashboards.each do |d|
          dashboard = GoodData::Dashboard.create(
            { title: d['title'] },
            client: client, project: @project
          )
          d['tabs'].each do |t|
            tab = dashboard.add_tab(title: t['title'])
            t['items'].each do |i|
              tab.add_report_item(report: GoodData::Report[i['identifier']],
                                  position_x: i['position']['x'],
                                  position_y: i['position']['y'],
                                  size_x: i['size']['width'],
                                  size_y: i['size']['height'])
            end

            tab.add_report_item(report: GoodData::Report['report.report.contains.ca'],
                                position_x: 0,
                                position_y: 0,
                                size_x: 640,
                                size_y:100)
          end
          dashboard_name = d['title'].to_s.downcase.gsub(/\s/, '.')
          dashboard.identifier = "dashboard.#{dashboard_name}"
          dashboard.add_tag('dashboard')
          dashboard.save
        end
      end
    end

    def create_tag_for_fact_n_dataset
      dataset = @project.datasets(DATASET_IDENTIFIER)
      dataset.add_tag('dataset')
      dataset.save

      fact = @project.facts(FACT_IDENTIFIER)
      fact.add_tag('fact')
      fact.save
    end

    def ensure_user(login, domain)
      user = domain.users(login)
      unless user
        user = domain.add_user(login: login)
      end
      @project.add_user(user, 'Viewer', domain: domain)
      user
    end
  end
end
