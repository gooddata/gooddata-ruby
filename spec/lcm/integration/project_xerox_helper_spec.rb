require_relative 'support/configuration_helper'
require_relative 'support/connection_helper'
require_relative 'shared_examples_for_synchronization_bricks'
require_relative 'support/project_helper'

describe GoodData::Helpers::ProjectXeroxHelper do
  before(:all) do
    config = LcmConnectionHelper.environment

    source_client = GoodData.connect(
      config[:username],
      config[:password],
      server: "https://#{config[:dev_server]}",
      verify_ssl: false
    )
    @target_client = GoodData.connect(
      config[:username],
      config[:password],
      server: "https://#{config[:prod_server]}",
      verify_ssl: false
    )
    $reuse_project = ENV['REUSE_PROJECT']
    project_helper = ConfigurationHelper.ensure_development_project(
      client: source_client,
      title: 'source project',
      auth_token: config[:dev_token],
      environment: 'TESTING',
      deploy_processes: true
    )

    @source = project_helper.project
    @targets = GoodData::Helpers::ProjectXeroxHelper.clone(
      @source,
      {
        username: config[:username],
        password: config[:password],
        hostname: config[:dev_server]
      },
      {
        username: config[:username],
        password: config[:password],
        hostname: config[:prod_server]
      },
      project_token: config[:gd_project_token]
    )
  end

  after(:all) do
    @targets.map(&:delete)
  end

  it_behaves_like 'a synchronization brick' do
    let(:original_project) { @source }
    let(:projects) { @targets }
    let(:schedules_status) { 'DISABLED' }
    let(:lcm_managed_tag) { false }
    let(:client_id_schedule_parameter) { false }
    let(:user_group) { true }
    let(:fact_id) { Support::FACT_IDENTIFIER }
    let(:additional_hidden_params) { {} }
    let(:output_stage_prefix) { nil }
    let(:prod_rest_client) { @target_client }
    let(:schedule_diff) { [] }
  end
end
