require_relative '../integration/support/constants'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/support/lcm_helper'
require_relative '../integration/brick_runner'
require_relative '../integration/shared_examples_for_synchronization_bricks'
require_relative '../integration/shared_contexts_for_lcm'

# global variables to simplify passing stuff between shared contexts and examples
$master_projects = []
$client_projects = []
$master = false

schedule_additional_hidden_params = {
  hidden_msg_from_release_brick: 'Hi, I was set by a brick but keep it secret',
  SECURE_PARAM_2: 'I AM SET TOO'
}

describe 'when using NFS instead of ADS for release data storage' do
  include_context 'lcm bricks',
                  ads: false,
                  schedule_additional_hidden_params: schedule_additional_hidden_params

  describe '1 - Initial Release' do
    before(:all) do
      $master_projects = BrickRunner.release_brick context: @test_context, template_path: '../params/release_brick.json.erb', client: @prod_rest_client
      $master = $master_projects.first
    end

    it_behaves_like 'a synchronization brick' do
      let(:original_project) { @project }
      let(:projects) { $master_projects }
      let(:schedules_status) { 'DISABLED' }
      let(:lcm_managed_tag) { false }
      let(:client_id_schedule_parameter) { false }
      let(:user_group) { true }
      let(:schedule_diff) do
        [['+', 'hiddenParams.hidden_msg_from_release_brick', nil],
         ['+', 'params.msg_from_release_brick', 'Hi, I was set by release brick']]
      end
      let(:fact_id) { Support::FACT_IDENTIFIER }
      let(:schedule_additional_hidden_params) { schedule_additional_hidden_params }
      let(:output_stage_prefix) { nil }
      let(:include_deprecated) { false }
    end
  end

  describe '2 - Initial Provisioning' do
    before(:all) do
      $client_projects = BrickRunner.provisioning_brick context: @test_context, template_path: '../params/provisioning_brick.json.erb', client: @prod_rest_client
    end

    it 'creates client projects only for filtered segments' do
      expect($client_projects.length).to be 3
    end

    it_behaves_like 'a synchronization brick' do
      let(:original_project) { $master }
      let(:projects) { $client_projects }
      let(:schedules_status) { 'ENABLED' }
      let(:lcm_managed_tag) { true }
      let(:client_id_schedule_parameter) { true }
      let(:user_group) { false }
      let(:schedule_diff) do
        [['+', 'params.msg_from_provisioning_brick', 'Hi, I was set by provisioning brick']]
      end
      let(:fact_id) { Support::FACT_IDENTIFIER }
      let(:schedule_additional_hidden_params) { schedule_additional_hidden_params }
      let(:output_stage_prefix) { nil }
      let(:include_deprecated) { false }
    end
  end

  describe '3 - Initial Rollout' do
    before(:all) do
      $client_projects = BrickRunner.rollout_brick context: @test_context, template_path: '../params/rollout_brick.json.erb', client: @prod_rest_client
    end

    it_behaves_like 'a synchronization brick' do
      let(:original_project) { $master }
      let(:projects) { $client_projects }
      let(:schedules_status) { 'ENABLED' }
      let(:lcm_managed_tag) { true }
      let(:client_id_schedule_parameter) { true }
      let(:user_group) { false }
      let(:schedule_diff) do
        [['+', 'params.msg_from_rollout_brick', 'Hi, I was set by rollout brick']]
      end
      let(:fact_id) { Support::FACT_IDENTIFIER }
      let(:schedule_additional_hidden_params) { schedule_additional_hidden_params }
      let(:output_stage_prefix) { nil }
      let(:include_deprecated) { false }
    end
  end

  describe '4 - Modify development project' do
    it 'modifies development project' do
      # add a report
      maql = 'SELECT AVG(![fact.csv_policies.income])'
      metric = @project.add_metric(
        maql,
        title: "Average Income #{GoodData::Environment::RANDOM_STRING}",
        identifier: "metric.average.income.#{GoodData::Environment::RANDOM_STRING}"
      )
      metric.save
      d = @project.dashboards.first
      tab = d.tabs.first
      report = @project.create_report(
        title: "Awesome report #{GoodData::Environment::RANDOM_STRING}",
        top: @project.metrics('attr.csv_policies.state'),
        left: [metric]
      )
      report.save
      tab.add_report_item(:report => report,
                          :position_x => 0,
                          :position_y => 300)
      d.save
    end
  end

  describe '5 - Subsequent Release' do
    before(:all) do
      $master_projects = BrickRunner.release_brick context: @test_context, template_path: '../params/release_brick.json.erb', client: @prod_rest_client
      $master = $master_projects.first
    end

    it_behaves_like 'a synchronization brick' do
      let(:original_project) { @project }
      let(:projects) { $master_projects }
      let(:schedules_status) { 'DISABLED' }
      let(:lcm_managed_tag) { false }
      let(:client_id_schedule_parameter) { false }
      let(:user_group) { true }
      let(:schedule_diff) do
        [['+', 'hiddenParams.hidden_msg_from_release_brick', nil],
         ['+', 'params.msg_from_release_brick', 'Hi, I was set by release brick']]
      end
      let(:fact_id) { Support::FACT_IDENTIFIER }
      let(:schedule_additional_hidden_params) { schedule_additional_hidden_params }
      let(:output_stage_prefix) { nil }
      let(:include_deprecated) { false }
    end
  end

  describe '6 - Subsequent Rollout' do
    before(:all) do
      $client_projects = BrickRunner.rollout_brick context: @test_context, template_path: '../params/rollout_brick.json.erb', client: @prod_rest_client
    end

    it_behaves_like 'a synchronization brick' do
      let(:original_project) { $master }
      let(:projects) { $client_projects }
      let(:schedules_status) { 'ENABLED' }
      let(:lcm_managed_tag) { true }
      let(:client_id_schedule_parameter) { true }
      let(:user_group) { false }
      let(:schedule_diff) do
        [['+', 'params.msg_from_rollout_brick', 'Hi, I was set by rollout brick']]
      end
      let(:fact_id) { Support::FACT_IDENTIFIER }
      let(:schedule_additional_hidden_params) { schedule_additional_hidden_params }
      let(:output_stage_prefix) { nil }
      let(:include_deprecated) { false }
    end
  end
end
