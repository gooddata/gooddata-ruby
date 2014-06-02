# encoding: UTF-8

require_relative 'project'
require_relative 'project_blueprint'

require 'open-uri'

module GoodData
  module Model
    class ProjectCreator
      class << self
        def migrate(options = {})
          spec = options[:spec] || fail('You need to provide spec for migration')
          bp = ProjectBlueprint.new(spec)
          spec = bp.to_hash

          fail GoodData::ValidationError, "Blueprint is invalid #{bp.validate.inspect}" unless bp.valid?

          token = options[:token]
          project = options[:project] || GoodData::Project.create(:title => spec[:title], :auth_token => token)
          fail('You need to specify token for project creation') if token.nil? && project.nil?

          begin
            GoodData.with_project(project) do |p|
              # migrate_date_dimensions(p, spec[:date_dimensions] || [])
              migrate_datasets(p, spec)
              load(p, spec)
              migrate_metrics(p, spec[:metrics] || [])
              migrate_reports(p, spec[:reports] || [])
              migrate_dashboards(p, spec[:dashboards] || [])
              migrate_users(p, spec[:users] || [])
              execute_tests(p, spec[:assert_tests] || [])
              p
            end
          end
        end

        def migrate_date_dimensions(project, spec)
          spec.each do |dd|
            Model.add_schema(DateDimension.new(dd), project)
          end
        end

        def migrate_datasets(project, spec)
          bp = ProjectBlueprint.new(spec)
          # schema = Schema.load(schema) unless schema.respond_to?(:to_maql_create)
          # project = GoodData.project unless project
          uri = "/gdc/projects/#{GoodData.project.pid}/model/diff"
          result = GoodData.post(uri, bp.to_wire_model)
          link = result['asyncTask']['link']['poll']
          response = GoodData.get(link, :process => false)
          # pp response
          while response.code != 200
            sleep 1
            GoodData.connection.retryable(:tries => 3, :on => RestClient::InternalServerError) do
              sleep 1
              response = GoodData.get(link, :process => false)
              # pp response
            end
          end
          response = GoodData.get(link)
          ldm_links = GoodData.get project.md[LDM_CTG]
          ldm_uri = Links.new(ldm_links)[LDM_MANAGE_CTG]
          chunks = pick_correct_chunks(response['projectModelDiff']['updateScripts'])
          chunks['updateScript']['maqlDdlChunks'].each do |chunk|
            response = GoodData.post ldm_uri, 'manage' => { 'maql' => chunk }
            polling_url = response['entries'].first['link']

            polling_result = GoodData.get(polling_url)
            while polling_result['wTaskStatus']['status'] == 'RUNNING'
              sleep(3)
              polling_result = GoodData.get(polling_url)
            end
            fail 'Creating dataset failed' if polling_result['wTaskStatus']['status'] == 'ERROR'

          end

          bp.datasets.each do |ds|
            schema = ds.to_schema
            GoodData::ProjectMetadata["manifest_#{schema.name}"] = schema.to_manifest.to_json
          end
        end

        def migrate_reports(project, spec)
          spec.each do |report|
            project.add_report(report)
          end
        end

        def migrate_dashboards(project, spec)
          spec.each do |dash|
            project.add_dashboard(dash)
          end
        end

        def migrate_metrics(project, spec)
          spec.each do |metric|
            project.add_metric(metric)
          end
        end

        def migrate_users(project, spec)
          spec.each do |user|
            puts "Would migrate user #{user}"
            # project.add_user(user)
          end
        end

        def load(project, spec)
          if spec.key?(:uploads)
            spec[:uploads].each do |load|
              schema = GoodData::Model::Schema.new(spec[:datasets].find { |d| d[:name] == load[:dataset] })
              project.upload(load[:source], schema, load[:mode])
            end
          end
        end

        def execute_tests(project, spec)
          spec.each do |assert|
            result = GoodData::ReportDefinition.execute(assert[:report])
            fail "Test did not pass. Got #{result.table.inspect}, expected #{assert[:result].inspect}" if result.table != assert[:result]
          end
        end

        def pick_correct_chunks(chunks)
          # first is cascadeDrops, second is preserveData
          rules = [
            [false, true],
            [false, false],
            [true, true],
            [true, false]
          ]
          stuff = chunks.select { |chunk| chunk['updateScript']['maqlDdlChunks'] }
          rules.reduce(nil) do |a, e|
            a || stuff.find { |chunk| e[0] == chunk['updateScript']['cascadeDrops'] && e[1] == chunk['updateScript']['preserveData'] }
          end
        end
      end
    end
  end
end
