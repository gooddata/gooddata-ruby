require 'active_support/core_ext/numeric/time'

require_relative '../integration/support/project_helper'
require_relative '../integration/support/connection_helper'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/support/s3_helper'
require_relative '../userprov/shared_contexts_for_user_bricks'
require_relative '../integration/spec/brick_runner'
require_relative '../helpers/schedule_helper'
require_relative 'shared_contexts_for_load_tests'

def user_in_domain(user_name)
  domain = @rest_client.domain(LcmConnectionHelper.environment[:prod_organization])
  domain.find_user_by_login(user_name)
end

# set up by execmgr-k8s
image_tag = ENV['LCM_BRICKS_IMAGE_TAG']

GoodData::Environment.const_set('VCR_ON', false)

user_array = []
user_count = ENV['GD_LCM_SPEC_USER_COUNT'] ? ENV['GD_LCM_SPEC_USER_COUNT'].to_i : 20
project_array = []
project_count = ENV['GD_LCM_SPEC_PROJECT_COUNT'] ? ENV['GD_LCM_SPEC_PROJECT_COUNT'].to_i : 20
service_project = nil
users_schedule = nil
user_filters_schedule = nil

describe 'UsersBrick' do
  include_context 'load tests cleanup' unless ENV['GD_LCM_SMOKE_TEST'] == 'true'

  before(:all) do
    @suffix = ConfigurationHelper.suffix
    @rest_client = LcmConnectionHelper.production_server_connection
    @domain = @rest_client.domain(LcmConnectionHelper.environment[:prod_organization])
    @opts = {
      client: @rest_client,
      title: "users brick load test #{@suffix}",
      auth_token: LcmConnectionHelper.environment[:prod_token],
      environment: 'TESTING'
    }
    project_helper = Support::ProjectHelper.create(@opts)
    project_helper.create_ldm
    project_helper.load_data
    @project = project_helper.project

    @user_name = "#{@suffix}@bar.baz"
    project_helper.ensure_user(@user_name, @domain)
    @user_data = {
      login: @user_name,
      first_name: 'first',
      last_name: 'last',
      company: 'GoodData',
      position: 'developer',
      country: 'CZech',
      phone: '123',
      language: 'fr-FR',
      user_groups: 'test_group',
      client_id: 'testingclient'
    }
    users_csv = ConfigurationHelper.csv_from_hashes([@user_data])
    s3_key = 'user_data'
    s3_info = Support::S3Helper.upload_file(users_csv, s3_key)

    @test_context = {
      project_id: @project.pid,
      config: LcmConnectionHelper.environment,
      s3_bucket: GoodData::Environment::ConnectionHelper::SECRETS[:s3_bucket_name],
      s3_key: s3_key
    }.merge(s3_info)
    @template_path = File.expand_path('../userprov/params/users_brick.json.erb', __dir__)
  end

  after(:each) do
    $SCRIPT_PARAMS = nil
  end

  context 'when using mode sync_multiple_projects_based_on_custom_id' do
    before(:all) do
      @test_context[:sync_mode] = 'sync_multiple_projects_based_on_custom_id'

      (1..user_count).each do |i|
        user_name = "#{@suffix}2_#{i}@bar.baz"
        @user_data[:login] = user_name
        user_array << @user_data.clone
      end
      (1..project_count).each do |j|
        (1..user_count).each do |i|
          user_name = "#{@suffix}2_#{i}_#{j}@bar.baz"
          @user_data[:login] = user_name
          @user_data[:client_id] = "testing_client_#{j}"
          user_array << @user_data.clone
        end
      end
      @domain.create_users(user_array)
      users_csv = ConfigurationHelper.csv_from_hashes(user_array)
      Support::S3Helper.upload_file(users_csv, @test_context[:s3_key])
      @data_product_id = "testing-data-product-#{@suffix}"
      @data_product = @domain.create_data_product(id: @data_product_id)
      @master_project = @rest_client.create_project(title: "Test MASTER project for #{@suffix}", auth_token: LcmConnectionHelper.environment[:prod_token])
      @segment = @data_product.create_segment(segment_id: "testing-segment-#{@suffix}", master_project: @master_project)
      @segment.create_client(id: 'testingclient', project: @project.uri)
      (1..project_count).each do |i|
        project_helper = Support::ProjectHelper.create(
          client: @rest_client,
          title: "Test MINOR project with testing_client_#{i} for #{@suffix}",
          auth_token: LcmConnectionHelper.environment[:prod_token],
          environment: 'TESTING'
        )
        project_helper.create_ldm
        project_helper.load_data
        project = project_helper.project

        @segment.create_client(id: "testing_client_#{i}", project: project.uri)
        project_array << project
      end

      @test_context[:data_product] = @data_product_id
      @config_path = ConfigurationHelper.create_interpolated_tempfile(
        @template_path,
        @test_context
      )
    end

    it 'adds users to project' do
      service_project = @rest_client.create_project(
        title: 'users load test service project',
        auth_token: @test_context[:config][:prod_token]
      )
      opts = {
        context: @test_context,
        template_path: '../../../userprov/params/users_brick.json.erb',
        image_tag: image_tag
      }
      users_schedule = BrickRunner.schedule_brick('users_brick', service_project, opts)
    end

    it 'sets the right MUFs to right users' do
      # @test_context = {
      #   project_id: @project.pid,
      #   config: LcmConnectionHelper.environment,
      #   s3_bucket: GoodData::Environment::ConnectionHelper::SECRETS[:s3_bucket_name],
      #   s3_endpoint: Support::S3Helper::S3_ENDPOINT,
      #   s3_key: 'user_data',
      #   users_brick_input: {
      #     s3_bucket: GoodData::Environment::ConnectionHelper::SECRETS[:s3_bucket_name],
      #     s3_endpoint: Support::S3Helper::S3_ENDPOINT,
      #     s3_key: 'users_brick_input'
      #   }
      # }
      # @ads = GoodData::DataWarehouse.create(
      #   client: @rest_client,
      #   title: 'TEST ADS',
      #   auth_token: LcmConnectionHelper.environment[:prod_token]
      # )
      # @test_context[:jdbc_url] = @ads.data['connectionUrl']
      # @ads_client = GoodData::Datawarehouse.new(
      #   @test_context[:config][:username],
      #   @test_context[:config][:password],
      #   nil,
      #   jdbc_url: @ads.data['connectionUrl']
      # )
      # query = 'CREATE TABLE IF NOT EXISTS "user_filters" (login VARCHAR(255) NOT NULL, state VARCHAR(255) NOT NULL, client_id VARCHAR(255));'
      # @ads_client.execute(query)
      # user_array.map do |u|
      #   insert = "INSERT INTO \"user_filters\" VALUES('#{u[:login]}', 'Oregon','#{u[:client_id]}');"
      #   @ads_client.execute(insert)
      # end
      # @test_context[:sync_mode] = 'sync_multiple_projects_based_on_custom_id'
      # @test_context[:data_product] = @data_product_id
      # @template_path = File.expand_path('../userprov/params/user_filters_brick_ads.json.erb', __dir__)
      # @config_path = ConfigurationHelper.create_interpolated_tempfile(
      #   @template_path,
      #   @test_context
      # )
      # user_filters_schedule = BrickRunner.schedule_brick(
      #   'user_filters_brick',
      #   service_project,
      #   context: @test_context,
      #   template_path: '../../../userprov/params/user_filters_brick_ads.json.erb',
      #   image_tag: image_tag,
      #   run_after: users_schedule
      # )
    end

    it 'executes the schedules' do
      users_schedule.execute(wait: false)
    end

    it 'successfully finishes' do
      # timeout = 3.hours
      # results = GoodData::AppStore::Helper.wait_for_executions(
      #   [users_schedule, user_filters_schedule],
      #   timeout
      # )
      # results.each do |result|
      #   expect(result.status).to be :ok
      # end
    end
  end
end
