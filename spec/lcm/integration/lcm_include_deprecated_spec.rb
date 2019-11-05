require_relative 'support/constants'
require_relative 'support/configuration_helper'
require_relative 'support/lcm_helper'
require_relative 'brick_runner'
require_relative 'shared_examples_for_synchronization_bricks'
require_relative 'shared_examples_for_provisioning_and_rollout'
require_relative 'shared_contexts_for_lcm'
require_relative 'shared_examples_for_release_brick'

# global variables to simplify passing stuff between shared contexts and examples
$master_projects = []
$client_projects = []
$master = false

output_stage_prefix = GoodData::Environment::VCR_ON ? nil : Support::OUTPUT_STAGE_PREFIX

schedule_additional_hidden_params = {
  hidden_msg_from_release_brick: 'Hi, I was set by a brick but keep it secret',
  SECURE_PARAM_2: 'I AM SET TOO'
}

process_additional_hidden_params = {
  process: {
    component: {
      configLocation: {
        s3: {
          path: 's3://s3_bucket/s3_folder/',
          accessKey: 's3_access_key',
          secretKey: 's3_secret_key',
          serverSideEncryption: true
        }
      }
    }
  }
}

describe 'the whole life-cycle', :vcr do
  include_context 'lcm bricks',
                  schedule_additional_hidden_params: schedule_additional_hidden_params,
                  process_additional_hidden_params: process_additional_hidden_params

  describe '1 - Initial Release' do
    before(:all) do
      ENV['VCR_RECORD_MODE'] = 'all'

      $master_projects = BrickRunner.release_brick context: @test_context, template_path: '../params/release_brick.json.erb', client: @prod_rest_client

      $client_projects = BrickRunner.provisioning_brick context: @test_context, template_path: '../params/provisioning_brick.json.erb', client: @prod_rest_client

      $client_projects = BrickRunner.rollout_brick context: @test_context, template_path: '../params/rollout_brick_include_deprecated.json.erb', client: @prod_rest_client

      $master = $master_projects.first

      fact = @project.facts.first
      fact.deprecated= 1
      fact.save

      attri = @project.attributes.first
      attri.deprecated= 1
      attri.save

      attri = nil
      @project.attributes.each do | att|
        attri = att if att.identifier == 'attr.csv_policies.education'
      end

      attri.deprecated= 1 unless attri.nil?
      attri.save unless attri.nil?

      $client_project = $client_projects.first

      fact = $client_project.facts.first
      fact.deprecated= 1
      fact.save

      attri = $client_project.attributes.first
      attri.deprecated= 1
      attri.save

      attri = nil
      $client_project.attributes.each do | att|
        if att.identifier == 'attr.csv_policies.policy_type'
          attri = att
          attri.deprecated= 1 unless attri.nil?
          attri.save unless attri.nil?
        end

        if att.identifier == 'attr.csv_policies.sales_channel'
          attri = att
          attri.deprecated= 1 unless attri.nil?
          attri.save unless attri.nil?
        end
      end

      $master_projects = BrickRunner.release_brick context: @test_context, template_path: '../params/release_brick.json.erb', client: @prod_rest_client

      $client_projects = BrickRunner.rollout_brick context: @test_context, template_path: '../params/rollout_brick_include_deprecated.json.erb', client: @prod_rest_client

    end

    it_behaves_like 'a synchronization brick' do
      let(:original_project) { $master }
      let(:projects) { $client_projects }
      let(:client_project) { $client_project}
      let(:schedules_status) { 'ENABLED' }
      let(:lcm_managed_tag) { true }
      let(:client_id_schedule_parameter) { true }
      let(:user_group) { false }
      let(:schedule_diff) do
        [['+', 'params.msg_from_rollout_brick', 'Hi, I was set by rollout brick']]
      end
      let(:fact_id) { Support::FACT_IDENTIFIER }
      let(:schedule_additional_hidden_params) { schedule_additional_hidden_params }
      let(:output_stage_prefix) { output_stage_prefix }
      let(:include_deprecated) { true }
    end

    it_behaves_like 'a provisioning or rollout brick' do
      let(:projects) { $client_projects }
    end
  end
end




