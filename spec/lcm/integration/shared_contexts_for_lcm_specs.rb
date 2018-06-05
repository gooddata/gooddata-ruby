require_relative 'support/configuration_helper'
require_relative 'support/project_helper'
require_relative 'support/connection_helper'
require_relative 'support/lcm_helper'
require 'gooddata_datawarehouse'

def create_suffix
  hostname = Socket.gethostname
  timestamp = DateTime.now.strftime('%Y%m%d%H%M%S')
  suffix = "#{hostname}_#{timestamp}"
  segment_name_forbidden_chars = /[^a-zA-Z0-9_\\-]+/
  suffix.scan(segment_name_forbidden_chars).each do |forbidden_characters|
    suffix.gsub!(forbidden_characters, '_')
  end
  suffix
end

def create_workspace_csv(workspaces, client_id_column)
  temp_file = Tempfile.new('workspace_csv')
  headers = [client_id_column, 'segment_id', 'project_title']

  CSV.open(temp_file, 'w', write_headers: true, headers: headers) do |csv|
    workspaces.each do |workspace|
      csv << [workspace[:client_id],
              workspace[:segment_id],
              workspace[:title]]
    end
  end
  temp_file
end

shared_context 'release brick' do
  before(:all) do
    config_path = ConfigurationHelper.create_interpolated_tempfile(
      @config_template_path,
      @test_context
    )
    params = JSON.parse(File.read(config_path))
    @brick_result = GoodData::Bricks::Pipeline.release_brick_pipeline.call(params)
    master_ids = @brick_result[:results]['CreateSegmentMasters'].map { |r| r[:master_pid] }
    $master_projects = master_ids.map { |id| @prod_rest_client.projects(id) }
    $master = $master_projects.first
    pp @brick_result
  end
end

shared_context 'provisioning brick' do
  before(:all) do
    config_path = ConfigurationHelper.create_interpolated_tempfile(
      @config_template_path,
      @test_context
    )
    params = JSON.parse(File.read(config_path))
    @brick_result = GoodData::Bricks::Pipeline.provisioning_brick_pipeline.call(params)
    client_pids = @brick_result[:params][:synchronize].first[:to].map(&:pid)
    $client_projects = client_pids.map { |id| @prod_rest_client.projects(id) }
    pp @brick_result
  end
end

shared_context 'rollout brick' do
  before(:all) do
    config_path = ConfigurationHelper.create_interpolated_tempfile(
      @config_template_path,
      @test_context
    )
    params = JSON.parse(File.read(config_path))
    @brick_result = GoodData::Bricks::Pipeline.rollout_brick_pipeline.call(params)
    client_pids = @brick_result[:params][:synchronize].first[:to].map(&:pid)
    $client_projects = client_pids.map { |id| @prod_rest_client.projects(id) }
    pp @brick_result
  end
end

shared_context 'lcm bricks' do
  before(:all) do
    @config = {
        verify_ssl: false,
        environment: 'TESTING',
        master_prefix: 'Insurance Demo Master'
    }
    @config.merge!(LcmConnectionHelper.environment)
    @config[:ads_client] = {
        username: @config[:username],
        password: @config[:password]
    }
    connection_parameters = {
        username: @config[:username],
        password: @config[:password],
        server: "https://#{@config[:dev_server]}"
    }
    @rest_client = GoodData.connect(connection_parameters)

    @ads = ConfigurationHelper.create_development_datawarehouse(client: @rest_client,
                                                                title: 'Development ADS',
                                                                auth_token: @config[:vertica_dev_token])

    @config[:ads_client][:jdbc_url] = @ads.data['connectionUrl']

    @ads_client = GoodData::Datawarehouse.new(
        @config[:ads_client][:username],
        @config[:ads_client][:password],
        @config[:ads_client][:ads_id],
        jdbc_url: @ads.data['connectionUrl']
    )

    @suffix = LcmHelper.create_suffix
    @release_table_name = "LCM_RELEASE_#{@suffix}"
    LcmHelper.create_release_table(@release_table_name, @ads_client)
    @workspace_table_name = "LCM_WORKSPACE_#{@suffix}"

    $reuse_project = ENV['REUSE_PROJECT']

    project_helper = ConfigurationHelper.create_development_project({
      client: @rest_client,
      title: "Development Project #{@suffix}",
      auth_token: @config[:dev_token],
      environment: @config[:environment],
      ads: @ads
    })
    project_helper.deploy_processes(@ads) unless $reuse_project
    @project = project_helper.project

    label = @project.labels.first
    @project.create_variable(title: 'uaaa', attribute: label.attribute).save unless $reuse_project
    label.meta['deprecated'] = 1
    label.save

    prod_connection_parameters = {
        username: @config[:username],
        password: @config[:password],
        server: "https://#{@config[:prod_server]}"
    }
    @prod_rest_client = GoodData.connect(prod_connection_parameters)
    @prod_ads = ConfigurationHelper.create_development_datawarehouse(client: @prod_rest_client,
                                                                     title: 'Production ADS',
                                                                     auth_token: @config[:prod_token])

    @prod_output_stage_project = ConfigurationHelper.create_output_stage_project(
        @prod_rest_client,
        @suffix,
        @prod_ads,
        @config[:prod_token],
        @config[:environment]
    )
    production_output_stage_uri = @prod_output_stage_project.add.output_stage.data['schema']

    segments = (['BASIC', 'PREMIUM'] * ($segments_multiplier || 1)).map.with_index do |segment, i|
      {
          segment_id: "INSURANCE_DEMO_#{segment}_#{i}_#{@suffix}",
          development_pid: @project.obj_id,
          driver: segment == 'PREMIUM' ? 'vertica' : 'pg',
          master_name: "Insurance Demo Master (#{segment} #{i}) " + '##{version}',
          ads_output_stage_uri: production_output_stage_uri
      }
    end
    segments_filter = segments.map { |s| s[:segment_id] }

    @workspaces = (segments * ($workspaces_multiplier || 2)).map.with_index do |segment, i|
      {
          client_id: "INSURANCE_DEMO_#{i}_#{@suffix}",
          segment_id: segment[:segment_id],
          title: "Insurance Demo Workspace #{i} #{@suffix}"
      }
    end

    s3_endpoint = 'http://localstack:4572'
    workspace_csv = LcmHelper.create_workspace_csv(
        @workspaces,
        Support::CUSTOM_CLIENT_ID_COLUMN
    )
    s3 = Aws::S3::Resource.new(access_key_id: 'foo',
                               secret_access_key: 'foo',
                               endpoint: s3_endpoint,
                               region: 'us-west-2',
                               force_path_style: true)

    bucket_name = 'testbucket'
    bucket = s3.bucket(bucket_name)
    bucket = s3.create_bucket(bucket: bucket_name) unless bucket.exists?
    obj = bucket.object(@workspace_table_name)
    obj.upload_file(Pathname.new(workspace_csv))

    @data_product_id = "DATA_PRODUCT_#{@suffix}"

    @test_context = {
        release_table_name: @release_table_name,
        workspace_table_name: @workspace_table_name,
        config: @config,
        ads_client: @ads_client,
        jdbc_url: @ads.data['connectionUrl'],
        development_pid: @project.obj_id,
        segments: segments.to_json,
        segments_filter: segments_filter.to_json,
        ads_output_stage_uri: production_output_stage_uri,
        data_product: @data_product_id,
        input_source_type: 's3',
        s3_bucket: bucket_name,
        s3_endpoint: s3_endpoint,
        custom_client_id_column: Support::CUSTOM_CLIENT_ID_COLUMN,
        transfer_all: true
    }
  end

  after(:each) do
    $SCRIPT_PARAMS = nil
  end

  after(:all) do
    projects_to_delete =
        $master_projects +
        $client_projects +
        [@prod_output_stage_project]

    projects_to_delete += [@project] unless ENV['REUSE_PROJECT']

    projects_to_delete.each do |project|
      begin
        # We need to delete the output stage explicitly
        # because of https://jira.intgdc.com/browse/DSS-2967
        project.add && project.add.output_stage && project.add.output_stage.delete
      rescue StandardError => e
        GoodData.logger.warn("Failed to delete output stage. #{e}")
        GoodData.logger.warn("Backtrace:\n#{e.backtrace.join("\n")}")
      end

      begin
        GoodData.logger.info("Deleting project \"#{project.title}\" with ID #{project.pid}")
        project.delete unless project.deleted?
      rescue StandardError => e
        GoodData.logger.warn("Failed to delete project #{project.title}. #{e}")
        GoodData.logger.warn("Backtrace:\n#{e.backtrace.join("\n")}")
      end
    end

    begin
      GoodData.logger.info("Deleting production ADS #{@ads.obj_id}")
      @prod_ads.delete
    rescue StandardError => e
      GoodData.logger.warn("Failed to delete production ADS. #{e}")
      GoodData.logger.warn("Backtrace:\n#{e.backtrace.join("\n")}")
    end

    begin
      GoodData.logger.info("Deleting development ADS #{@ads.obj_id}")
      @ads.delete
    rescue StandardError => e
      GoodData.logger.warn("Failed to delete development ADS. #{e}")
      GoodData.logger.warn("Backtrace:\n#{e.backtrace.join("\n")}")
    end

    begin
      GoodData.logger.info("Deleting segments")
      domain = @rest_client.domain(@config[:prod_organization])
      data_product = domain.data_products(@data_product_id)
      data_product.delete(force: true)
    rescue StandardError => e
      GoodData.logger.warn("Failed to delete segments. #{e}")
      GoodData.logger.warn("Backtrace:\n#{e.backtrace.join("\n")}")
    end

    @rest_client.disconnect if @rest_client
    @prod_rest_client.disconnect if @rest_client
  end
end
