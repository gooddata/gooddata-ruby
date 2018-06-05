require_relative 'support/project_helper'
require_relative 'support/connection_helper'
require_relative 'support/configuration_helper'
require_relative 'support/s3_helper'
require_relative 'shared_examples_for_user_bricks'

def user_in_domain(user_name)
  domain = @rest_client.domain(LcmConnectionHelper.environment[:prod_organization])
  domain.find_user_by_login(user_name)
end

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
    @project = project_helper.project
    @test_context = {
      project_id: @project.pid,
      config: LcmConnectionHelper.environment,
      s3_bucket: Support::S3Helper::BUCKET_NAME,
      s3_endpoint: Support::S3Helper::S3_ENDPOINT,
      s3_key: 'user_data'
    }
    @template_path = File.expand_path('../params/users_brick.json.erb', __FILE__)
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
    begin
      GoodData.logger.info("Deleting project \"#{@project.title}\" with ID #{@project.pid}")
      @project.delete unless @project.deleted? || !@project
    rescue StandardError => e
      GoodData.logger.warn("Failed to delete project #{@project.title}. #{e}")
      GoodData.logger.warn("Backtrace:\n#{e.backtrace.join("\n")}")
    end
    user_in_domain(@user_name).delete if @user_name
    $SCRIPT_PARAMS = nil
  end

  context 'when using mode sync_domain_and_project' do
    before do
      @test_context[:data_product] = 'default'
      @test_context[:sync_mode] = 'sync_domain_and_project'
      @config_path = ConfigurationHelper.create_interpolated_tempfile(
        @template_path,
        @test_context
      )
    end

    it 'adds users to domain' do
      params = JSON.parse(File.read(@config_path))
      GoodData::Bricks::Pipeline.users_brick_pipeline.call(params)
      new_user = user_in_domain(@user_name)
      expect(new_user).to be
      expect(new_user.first_name).to eq 'first'
      expect(new_user.last_name).to eq 'last'
      expect(new_user.language).to eq 'fr-FR'
      expect(new_user.company).to eq 'GoodData'
      expect(new_user.position).to eq 'developer'
      expect(new_user.country).to eq 'CZech'
      expect(new_user.phone).to eq '123'

      group = @project.user_groups('test_group')
      expect(group).not_to be_nil

      expect(group.member?(new_user)).to be_truthy
    end
  end

  context 'when using mode sync_multiple_projects_based_on_custom_id' do
    before do
      @test_context[:sync_mode] = 'sync_multiple_projects_based_on_custom_id'
      @user_name = "#{@suffix}2@bar.baz"
      @user_data[:login] = @user_name
      @domain.create_users([@user_data])
      users_csv = ConfigurationHelper.csv_from_hashes([@user_data])
      Support::S3Helper.upload_file(users_csv, @test_context[:s3_key])
    end

    after(:each) do
      @data_product.delete(force: true) if @data_product
    end

    after(:all) do
      user = user_in_domain(@user_name)
      user.delete
    end

    context 'when data product with correct client is passed' do
      before do
        data_product_id = "testing-data-product-#{@suffix}"
        @data_product = @domain.create_data_product(id: data_product_id)
        @master_project = @rest_client.create_project(title: "Test MASTER project for #{@suffix}", auth_token: LcmConnectionHelper.environment[:prod_token])
        @segment = @data_product.create_segment(segment_id: "testing-segment-#{@suffix}", master_project: @master_project)
        @segment.create_client(id: 'testingclient', project: @project.uri)

        @test_context[:data_product] = data_product_id
        @config_path = ConfigurationHelper.create_interpolated_tempfile(
          @template_path,
          @test_context
        )
      end

      it 'adds users to project' do
        params = JSON.parse(File.read(@config_path))
        GoodData::Bricks::Pipeline.users_brick_pipeline.call(params)
        expect(@project.member?(@user_name)).to be_truthy
      end

      after do
        @master_project.delete if @master_project
      end
    end

    context 'when data product without client is passed' do
      before do
        data_product_id = "testing-data-product-2-#{@suffix}"
        @data_product = @domain.create_data_product(id: data_product_id)

        @test_context[:data_product] = data_product_id
        @config_path = ConfigurationHelper.create_interpolated_tempfile(
          @template_path,
          @test_context
        )
      end

      it 'does not add any users and fails' do
        params = JSON.parse(File.read(@config_path))
        expect { GoodData::Bricks::Pipeline.users_brick_pipeline.call(params) }.to raise_error /does not exist in data product/
        expect(@project.member?(@user_name)).to be_falsey
      end
    end
  end

  context 'when using sync_domain_client_workspaces' do
    include_context 'a user action in sync_domain_client_workspaces mode'

    it 'adds users only on projects from clients in segments in segments filter' do
      GoodData::Bricks::Pipeline.users_brick_pipeline.call($SCRIPT_PARAMS)
      expect(@project.users.to_a.length).to be(2)
      expect(@project_not_in_filter.users.to_a.length).to be(1)
    end
  end
end
