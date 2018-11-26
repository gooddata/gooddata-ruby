require_relative '../integration/support/project_helper'
require_relative '../integration/support/connection_helper'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/support/s3_helper'
require_relative '../integration/red_contexts_for_user_bricks'

def user_in_domain(user_name)
  domain = @rest_client.domain(LcmConnectionHelper.environment[:prod_organization])
  domain.find_user_by_login(user_name)
end

user_array = []
user_count = 20
project_array = []
project_count = 20

describe 'UsersBrick' do
  before(:each) do
    @suffix = ConfigurationHelper.suffix
    @rest_client = LcmConnectionHelper.production_server_connection
    @domain = @rest_client.domain(LcmConnectionHelper.environment[:prod_organization])
    @opts = {
      client: @rest_client,
      title: "Project #{@suffix}",
      auth_token: LcmConnectionHelper.environment[:prod_token],
      environment: 'TESTING'
    }
    project_helper = Support::ProjectHelper.create(@opts)
    project_helper.create_ldm
    project_helper.load_data
    @project = project_helper.project
    @test_context = {
      project_id: @project.pid,
      config: LcmConnectionHelper.environment,
      s3_bucket: Support::S3Helper::BUCKET_NAME,
      s3_endpoint: Support::S3Helper::S3_ENDPOINT,
      s3_key: 'user_data'
    }
    @template_path = File.expand_path('../../integration/params/users_brick.json.erb', __FILE__)
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
    Support::S3Helper.upload_file(users_csv, @test_context[:s3_key])
  end

  after(:each) do
    $SCRIPT_PARAMS = nil
  end

  context 'when using mode sync_multiple_projects_based_on_custom_id' do
    before do
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

    after(:all) do
      @master_project.delete if @master_project
      @data_product.delete(force: true) if @data_product
      @rest_client = LcmConnectionHelper.production_server_connection
      user_array.each do |u|
        user = user_in_domain(u[:login])
        user.delete
      end
      @ads.delete if @ads
      begin
        GoodData.logger.info("Deleting project \"#{@project.title}\" with ID #{@project.pid}")
        @project.delete unless @project.deleted? || !@project
      rescue StandardError => e
        GoodData.logger.warn("Failed to delete project #{@project.title}. #{e}") unless @project.nil?
        GoodData.logger.warn("Backtrace:\n#{e.backtrace.join("\n")}")
      end
      user_in_domain(@user_name).delete if @user_name
      project_array.map do |proj|
        proj.delete unless proj.deleted? || !proj
      end
    end

    it 'adds users to project' do
      $SCRIPT_PARAMS = JSON.parse(File.read(@config_path))
      GoodData::Bricks::Pipeline.users_brick_pipeline.call($SCRIPT_PARAMS)
      user_array.each do |u|
        this_project = project_array.detect { |project| project.title.include? u[:client_id] }
        expect(this_project.member?(u)).to be_truthy unless this_project.nil?
      end
    end

    it 'sets the right MUFs to right users' do
      $SCRIPT_PARAMS = JSON.parse(File.read(@config_path))
      @test_context = {
        project_id: @project.pid,
        config: LcmConnectionHelper.environment,
        s3_bucket: Support::S3Helper::BUCKET_NAME,
        s3_endpoint: Support::S3Helper::S3_ENDPOINT,
        s3_key: 'user_data',
        users_brick_input: {
          s3_bucket: Support::S3Helper::BUCKET_NAME,
          s3_endpoint: Support::S3Helper::S3_ENDPOINT,
          s3_key: 'users_brick_input'
        }
      }
      @ads = GoodData::DataWarehouse.create(
        client: @rest_client,
        title: 'TEST ADS',
        auth_token: LcmConnectionHelper.environment[:prod_token]
      )
      @test_context[:jdbc_url] = @ads.data['connectionUrl']
      @ads_client = GoodData::Datawarehouse.new(
        @test_context[:config][:username],
        @test_context[:config][:password],
        nil,
        jdbc_url: @ads.data['connectionUrl']
      )
      query = 'CREATE TABLE IF NOT EXISTS "user_filters" (login VARCHAR(255) NOT NULL, state VARCHAR(255) NOT NULL, client_id VARCHAR(255));'
      @ads_client.execute(query)
      user_array.map do |u|
        insert = "INSERT INTO \"user_filters\" VALUES('#{u[:login]}', 'Oregon','#{u[:client_id]}');"
        @ads_client.execute(insert)
      end
      @test_context[:sync_mode] = 'sync_multiple_projects_based_on_custom_id'
      @test_context[:data_product] = @data_product_id
      @template_path = File.expand_path('../../integration/params/user_filters_brick_ads.json.erb', __FILE__)
      @config_path = ConfigurationHelper.create_interpolated_tempfile(
        @template_path,
        @test_context
      )
      $SCRIPT_PARAMS = JSON.parse(File.read(@config_path))
      GoodData::Bricks::Pipeline.user_filters_brick_pipeline.call($SCRIPT_PARAMS)
      GoodData.connection.connect
      project_array.map do |proj|
        proj.user_filters.map do |muf|
          expect(GoodData::Profile[muf.json[:related]].json["accountSetting"]["email"].scan(/[^\d]*\d*[_]\d*_(\d*)@bar\.baz/).first.last)
            .to eq proj.title.scan(/testing_client_(\d*)/).first.last
        end
      end
    end
  end
end
