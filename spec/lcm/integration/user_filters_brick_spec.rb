require_relative 'support/project_helper'
require_relative 'support/connection_helper'
require_relative 'support/configuration_helper'
require_relative 'support/s3_helper'
require_relative 'shared_examples_for_user_bricks'

def upload_user_filters_csv(user_filters)
  filters_csv = ConfigurationHelper.csv_from_hashes(user_filters)
  Support::S3Helper.upload_file(filters_csv, @test_context[:s3_key])
end

shared_context 'client mode' do
  before(:all) do
    synced_data_product_id = "testing-data-product-#{@suffix}"
    @data_product = @domain.create_data_product(id: synced_data_product_id)
    @master_project = @rest_client.create_project(title: "Test MASTER project for #{@suffix}", auth_token: LcmConnectionHelper.environment[:prod_token])
    @segment = @data_product.create_segment(segment_id: "testing-segment-#{@suffix}", master_project: @master_project)
    @segment.create_client(id: 'testingclient', project: @project.uri)
    @test_context[:data_product] = synced_data_product_id
  end

  after(:all) do
    @data_product.delete(force: true) if @data_product
    @master_project.delete if @master_project
  end
end

shared_context 'user filters brick test context' do
  before(:all) do
    @rest_client = LcmConnectionHelper.production_server_connection
    @suffix = ConfigurationHelper.suffix
    @opts = {
      client: @rest_client,
      title: "Project #{@suffix}",
      auth_token: LcmConnectionHelper.environment[:prod_token],
      environment: 'TESTING',
      prod_organization: 'staging-lcm-prod'
    }
    @domain = @rest_client.domain(LcmConnectionHelper.environment[:prod_organization])
    @project_helper = Support::ProjectHelper.create(@opts)
    @project_helper.create_ldm
    @project_helper.load_data
    @project = @project_helper.project

    domain = @rest_client.domain(LcmConnectionHelper.environment[:prod_organization])
    state_attribute = @project.attributes('attr.csv_policies.state')
    state_label = state_attribute.primary_label

    test_login = 'iam@atest.com'
    @test_user = @project_helper.ensure_user(test_login, domain)
    login_to_be_deleted = 'iam@tobedeleted.com'
    @user_to_be_deleted = @project_helper.ensure_user(login_to_be_deleted, domain)
    promoted_login = 'iam@promoted.com'
    @promoted_user = @project_helper.ensure_user(promoted_login, domain)
    filters = [[login_to_be_deleted, state_label.uri, 'Washington'],
               [promoted_login, state_label.uri, 'Washington']]
    @project.add_data_permissions(filters)

    @test_context = {
      project_id: @project.pid,
      config: LcmConnectionHelper.environment,
      s3_bucket: Support::S3Helper::BUCKET_NAME,
      s3_endpoint: Support::S3Helper::S3_ENDPOINT,
      s3_key: 'user_filters',
      users_brick_input: {
        s3_bucket: Support::S3Helper::BUCKET_NAME,
        s3_endpoint: Support::S3Helper::S3_ENDPOINT,
        s3_key: 'users_brick_input'
      }
    }
    @template_path = File.expand_path(
      '../params/user_filters_brick.json.erb',
      __FILE__
    )

    upload_user_filters_csv([{
                                 login: 'rubydev+admin@gooddata.com',
                                 state: 'Washington',
                                 client_id: 'testingclient'
                             }])

    user_data = [
      {
        custom_login: 'rubydev+admin@gooddata.com',
        first_name: 'first',
        last_name: 'last',
        company: 'GoodData',
        position: 'developer',
        country: 'CZech',
        phone: '123',
        language: 'fr-FR',
        user_groups: 'test_group'
      },
      {
        custom_login: promoted_login
      },
      {
        custom_login: test_login
      }
    ]
    users_csv = ConfigurationHelper.csv_from_hashes(user_data)
    Support::S3Helper.upload_file(users_csv, @test_context[:users_brick_input][:s3_key])
  end

  after(:all) do
    begin
      GoodData.logger.info("Deleting project \"#{@project.title}\" with ID #{@project.pid}")
      @project.delete if @project && !@project.deleted?
    rescue StandardError => e
      GoodData.logger.warn("Failed to delete project #{@project && @project.title}. #{e}")
      GoodData.logger.warn("Backtrace:\n#{e.backtrace.join("\n")}")
    end

    $SCRIPT_PARAMS = nil
  end
end

describe 'UsersFiltersBrick' do
  context 'when using sync_project mode' do
    include_context 'user filters brick test context'
    before(:all) do
      @test_context[:sync_mode] = 'sync_project'
      @test_context[:data_product] = 'default'
      config_path = ConfigurationHelper.create_interpolated_tempfile(
        @template_path,
        @test_context
      )

      $SCRIPT_PARAMS = JSON.parse(File.read(config_path))
      GoodData::Bricks::Pipeline.user_filters_brick_pipeline.call($SCRIPT_PARAMS)
      @filters = @project.user_filters.to_a
    end

    it 'updates user filters' do
      expect(@filters.length).to be(2)
    end

    it 'adds a user filter to the project' do
      result = @filters.select do |filter|
        filter.json[:related] == @rest_client.user.uri
      end
      expect(result.length).to be(1)
    end

    it 'keeps user filter for user not present in users brick input' do
      result = @filters.select do |filter|
        filter.json[:related] == @user_to_be_deleted.uri
      end
      expect(result.length).to be(1)
    end

    it 'deletes user filter for user present in users brick input' do
      result = @filters.select do |filter|
        filter.json[:related] == @promoted_user.uri
      end
      expect(result.length).to be(0)
    end
  end

  context 'when using sync_one_project_based_on_custom_id mode' do
    context 'when the project belongs to the specified data_product' do
      include_context 'user filters brick test context'
      include_context 'client mode'
      before(:all) do
        @test_context[:sync_mode] = 'sync_one_project_based_on_custom_id'
        config_path = ConfigurationHelper.create_interpolated_tempfile(
          @template_path,
          @test_context
        )

        $SCRIPT_PARAMS = JSON.parse(File.read(config_path))
      end

      it 'synces the project user filters' do
        GoodData::Bricks::Pipeline.user_filters_brick_pipeline.call($SCRIPT_PARAMS)
        expect(@project.user_filters.to_a.length).to be(2)
      end
    end

    context 'when the project does not belong to the specified data product' do
      include_context 'user filters brick test context'
      before(:all) do
        unsynced_data_product_id = "testing-unsynced-data-product-#{@suffix}"
        @data_product = @domain.create_data_product(id: unsynced_data_product_id)
        @master_project = @rest_client.create_project(title: "Test MASTER project 2 for #{@suffix}", auth_token: LcmConnectionHelper.environment[:prod_token])
        @segment = @data_product.create_segment(segment_id: "testing-segment-2-#{@suffix}", master_project: @master_project)
        @segment.create_client(id: 'testingclient')
        @test_context[:data_product] = unsynced_data_product_id
        @test_context[:sync_mode] = 'sync_one_project_based_on_custom_id'
        config_path = ConfigurationHelper.create_interpolated_tempfile(
          @template_path,
          @test_context
        )

        $SCRIPT_PARAMS = JSON.parse(File.read(config_path))
      end

      it 'fails because the client set is empty' do
        expect { GoodData::Bricks::Pipeline.user_filters_brick_pipeline.call($SCRIPT_PARAMS) }.to raise_error(/unable to get the values for user filters/)
      end
    end
  end

  context 'when using sync_domain_client_workspaces' do
    include_context 'user filters brick test context'
    include_context 'a user action in sync_domain_client_workspaces mode'
    let(:user_filters) do
      [{
           login: 'rubydev+admin@gooddata.com',
           state: 'Washington',
           client_id: 'testingclient'
       },
       {
           login: 'rubydev+admin@gooddata.com',
           state: 'Oregon',
           client_id: 'testingclient-not-in-filter'
       }]
    end

    before do
      upload_user_filters_csv(user_filters)
    end

    it 'adds user filters only on projects from clients in segments in segments filter' do
      GoodData::Bricks::Pipeline.user_filters_brick_pipeline.call($SCRIPT_PARAMS)
      expect(@project.user_filters.to_a.length).to be(2)
      expect(@project_not_in_filter.user_filters.to_a.length).to be(0)
    end
  end

  context 'when using sync_multiple_projects_based_on_custom_id mode' do
    context 'when input source is ADS' do
      include_context 'user filters brick test context'
      include_context 'client mode'
      before(:all) do
        @test_context[:sync_mode] = 'sync_multiple_projects_based_on_custom_id'

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

        ads_template_path = File.expand_path(
          '../params/user_filters_brick_ads.json.erb',
          __FILE__
        )

        query = 'CREATE TABLE IF NOT EXISTS "user_filters" (login VARCHAR(255) NOT NULL, state VARCHAR(255) NOT NULL, client_id VARCHAR(255));'
        @ads_client.execute(query)
        insert = "INSERT INTO \"user_filters\" VALUES('#{@test_user.login}', 'Oregon','testingclient');"
        @ads_client.execute(insert)

        config_path = ConfigurationHelper.create_interpolated_tempfile(
          ads_template_path,
          @test_context
        )

        $SCRIPT_PARAMS = JSON.parse(File.read(config_path))
        @original_params = $SCRIPT_PARAMS.dup
      end

      after(:all) do
        @ads.delete if @ads
      end

      it 'updates changed user filter' do
        GoodData::Bricks::Pipeline.user_filters_brick_pipeline.call($SCRIPT_PARAMS)
        filters = @project.user_filters.to_a
        expect(filters.to_a.length).to be(3)
        test_user_filters = filters.select do |f|
          f.related.login == @test_user.login
        end
        expect(test_user_filters.one?).to be(true)
        expression = test_user_filters.first.pretty_expression
        expect(expression).to eq('[State] IN ([Oregon])')
        update = %[UPDATE "user_filters" SET state = 'Arizona']
        @ads_client.execute(update)
        $SCRIPT_PARAMS = @original_params.dup
        GoodData::Bricks::Pipeline.user_filters_brick_pipeline.call($SCRIPT_PARAMS)
        filters = @project.user_filters.to_a
        expect(filters.to_a.length).to be(3)
        test_user_filters = filters.select do |f|
          f.related.login == @test_user.login
        end
        expect(test_user_filters.one?).to be(true)
        expression = test_user_filters.first.pretty_expression
        expect(expression).to eq('[State] IN ([Arizona])')
      end
    end
  end

  context 'when trying to add filter to user with UPPERCASE email address' do
    include_context 'user filters brick test context'
    before(:all) do
      @uppercase_login = 'test+UPPERCASE@domain.com'
      upload_user_filters_csv([{
                                   login: @uppercase_login,
                                   state: 'Washington',
                                   client_id: 'testingclient'
                               }])
      # add user only to domain, not to project to ensure behaviour with api calls using the email string
      unless @domain.users(@uppercase_login)
        @domain.add_user(login: @uppercase_login)
      end
      user_data = [{
                       custom_login: @uppercase_login
                   }]
      users_csv = ConfigurationHelper.csv_from_hashes(user_data)
      Support::S3Helper.upload_file(users_csv, @test_context[:users_brick_input][:s3_key])
    end

    it 'adds the MUF to the user' do
      @test_context[:sync_mode] = 'sync_project'
      @test_context[:data_product] = 'default'
      config_path = ConfigurationHelper.create_interpolated_tempfile(
          @template_path,
          @test_context
      )
      $SCRIPT_PARAMS = JSON.parse(File.read(config_path))
      GoodData::Bricks::Pipeline.user_filters_brick_pipeline.call($SCRIPT_PARAMS)
      filters = @project.user_filters.to_a
      expect(filters.find { |f| f.related.email == @uppercase_login })
    end
  end

  context 'when the user input is empty' do
    include_context 'user filters brick test context'
    before(:all) do
      another_login = 'test@login.com'
      @project_helper.ensure_user(another_login, @domain)
      upload_user_filters_csv([{
                                   login: 'test@login.com',
                                   state: 'Washington',
                                   client_id: 'testingclient'
                               }])
      users_csv = ConfigurationHelper.csv_from_hashes([])
      Support::S3Helper.upload_file(users_csv, @test_context[:users_brick_input][:s3_key])
    end

    it 'does not remove any mufs' do
      @test_context[:sync_mode] = 'sync_project'
      @test_context[:data_product] = 'default'
      config_path = ConfigurationHelper.create_interpolated_tempfile(
          @template_path,
          @test_context
      )
      $SCRIPT_PARAMS = JSON.parse(File.read(config_path))
      GoodData::Bricks::Pipeline.user_filters_brick_pipeline.call($SCRIPT_PARAMS)
      filters = @project.user_filters.to_a
      expect(filters.length).to be 3
    end
  end
end
