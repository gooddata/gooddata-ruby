require_relative 'support/project_helper'
require_relative 'support/connection_helper'
require_relative 'support/configuration_helper'
require_relative 'support/s3_helper'
require 'securerandom'

def user_in_domain(user_name)
  domain = @rest_client.domain(LcmConnectionHelper.environment[:prod_organization])
  domain.find_user_by_login(user_name)
end

describe GoodData::SplunkLogger do
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
    @template_path = File.expand_path('params/splunk_spec.json.erb', __dir__)
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

    @test_context[:data_product] = 'default'
    @test_context[:sync_mode] = 'sync_domain_and_project'
    @config_path = ConfigurationHelper.create_interpolated_tempfile(
      @template_path,
      @test_context
    )
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

  context 'when splunk logging is switched off' do
    it 'adds users to domain' do
      params = JSON.parse(File.read(@config_path))
      params['SPLUNK_LOGGING'] = 'false'
      GoodData::Bricks::Pipeline.users_brick_pipeline.call(params)
      expect(GoodData.gd_logger.logging_on?(:splunk)).to be_falsey
    end
  end

  context 'when using mode sync_domain_and_project' do
    prefix = SecureRandom.urlsafe_base64(16)
    let(:file_name) { "splunk_#{prefix}.log" }

    it 'adds users to domain' do
      params = JSON.parse(File.read(@config_path))
      params['SPLUNK_LOGGING'] = 'true'
      params['SPLUNK_LOG_PATH'] = file_name
      GoodData::Bricks::Pipeline.users_brick_pipeline.call(params)

      expect(GoodData.gd_logger.logging_on?(:splunk)).to be_truthy

      file = File.open file_name
      content = file.read
      file.close
      expect(content).to include "INFO"
      # File.delete file_name
    end
  end
end
