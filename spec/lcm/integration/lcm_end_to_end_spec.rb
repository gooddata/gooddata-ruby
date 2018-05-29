require 'pp'
require 'aws-sdk'
require 'tempfile'
require 'csv'

require_relative 'support/constants'
require_relative 'support/configuration_helper'
require_relative 'support/lcm_helper'
require_relative 'shared_examples_for_synchronization_bricks'
require_relative 'shared_contexts_for_lcm_specs'

# global variables to simplify passing stuff between shared contexts and examples
$master_projects = []
$client_projects = []
$master = false

describe 'the whole life-cycle' do
  include_context 'lcm bricks'

  describe '1 - Initial Release' do
    before(:all) do
      @config_template_path = File.expand_path(
        '../params/release_brick.json.erb',
        __FILE__
      )
    end

    include_context 'release brick'

    it_behaves_like 'a synchronization brick' do
      let(:original_project) { @project }
      let(:projects) { $master_projects }
      let(:schedules_status) { 'DISABLED' }
      let(:lcm_managed_tag) { false }
      let(:update_operations) { [] }
      let(:update_scripts) { [] }
      let(:client_id_schedule_parameter) { false }
      let(:user_group) { true }
      let(:schedule_diff) do
        [['+', 'hiddenParams.hidden_msg_from_release_brick', nil],
         ['+', 'params.msg_from_release_brick', 'Hi, I was set by release brick']]
      end
    end
  end

  describe '2 - Initial Provisioning' do
    before(:all) do
      @config_template_path = File.expand_path(
        '../params/provisioning_brick.json.erb',
        __FILE__
      )
    end

    include_context 'provisioning brick'

    it 'creates client projects only for filtered segments' do
      expect($client_projects.length).to be 2
    end

    it_behaves_like 'a synchronization brick' do
      let(:original_project) { $master }
      let(:projects) { $client_projects }
      let(:schedules_status) { 'ENABLED' }
      let(:lcm_managed_tag) { true }
      let(:update_operations) { [] }
      let(:update_scripts) { [] }
      let(:client_id_schedule_parameter) { true }
      let(:user_group) { false }
      let(:schedule_diff) do
        [['+', 'hiddenParams.hidden_msg_from_provisioning_brick', nil],
         ['+', 'params.msg_from_provisioning_brick', 'Hi, I was set by provisioning brick']]
      end
    end
  end

  describe '3 - Initial Rollout' do
    before(:all) do
      @config_template_path = File.expand_path(
        '../params/rollout_brick.json.erb',
        __FILE__
      )
    end

    include_context 'rollout brick'

    it_behaves_like 'a synchronization brick' do
      let(:original_project) { $master }
      let(:projects) { $client_projects }
      let(:schedules_status) { 'ENABLED' }
      let(:lcm_managed_tag) { true }
      let(:update_operations) do
        [
          {
            'updateOperation' => {
              'type' => 'dataset.drop',
              'dataset' => 'dataset.quotes',
              'destructive' => true,
              'description' => "Drop dataset '%s'",
              'parameters' => ['Stock Quotes Data']
            }
          }
        ]
      end
      let(:update_scripts) do
        [
          {
            'updateScript' => {
              'maqlDdl' => "DROP ALL IN {dataset.quotes} CASCADE;\n",
              'maqlDdlChunks' => ["DROP ALL IN {dataset.quotes} CASCADE;\n"],
              'preserveData' => true,
              'cascadeDrops' => true
            }
          },
          {
            'updateScript' => {
              'maqlDdl' => "DROP ALL IN {dataset.quotes} CASCADE;\n",
              'maqlDdlChunks' => ["DROP ALL IN {dataset.quotes} CASCADE;\n"],
              'preserveData' => false,
              'cascadeDrops' => true
            }
          }
        ]
      end
      let(:client_id_schedule_parameter) { true }
      let(:user_group) { false }
      let(:schedule_diff) do
        [['+', 'hiddenParams.hidden_msg_from_rollout_brick', nil],
         ['+', 'params.msg_from_rollout_brick', 'Hi, I was set by rollout brick']]
      end
    end
  end

  describe '4 - Modify development project' do
    it 'modifies development project' do
      skip 'bug'
      @project.schedules.each(&:disable!)
    end
  end

  describe '5 - Subsequent Release' do
    before(:all) do
      @config_template_path = File.expand_path(
        '../params/release_brick.json.erb',
        __FILE__
      )
    end

    include_context 'release brick'

    it_behaves_like 'a synchronization brick' do
      let(:original_project) { @project }
      let(:projects) { $master_projects }
      let(:schedules_status) { 'DISABLED' }
      let(:lcm_managed_tag) { false }
      let(:update_operations) { [] }
      let(:update_scripts) { [] }
      let(:client_id_schedule_parameter) { false }
      let(:user_group) { true }
      let(:schedule_diff) do
        [['+', 'hiddenParams.hidden_msg_from_release_brick', nil],
         ['+', 'params.msg_from_release_brick', 'Hi, I was set by release brick']]
      end
    end
  end

  describe '6 - Subsequent Provisioning' do
    before(:all) do
      @config_template_path = File.expand_path(
        '../params/provisioning_brick.json.erb',
        __FILE__
      )
      LcmHelper.create_workspace_table(
        @workspace_table_name,
        @ads_client,
        Support::CUSTOM_CLIENT_ID_COLUMN
      )
      deleted_workspace = @workspaces.delete(@workspaces.sample)
      @deleted_workspace = @prod_rest_client.projects(:all).find { |p| p.title == deleted_workspace[:title] }
      @test_context[:input_source_type] = 'ads'
      # add another workspace to provision
      @workspaces << {
          client_id: "INSURANCE_DEMO_NEW_#{@suffix}",
          segment_id: @workspaces.first[:segment_id],
          title: "Insurance Demo Workspace NEW #{@suffix}"
      }
      # copy existing workspaces ADS as we change data source
      @workspaces.each do |ws|
        query = "INSERT INTO \"#{@workspace_table_name}\" VALUES('#{ws[:client_id]}', '#{ws[:segment_id]}', NULL, '#{ws[:title]}');"
        @ads_client.execute(query)
      end
    end
    include_context 'provisioning brick'

    it 'deletes extra client projects' do
      expect(@brick_result[:params][:clients].map(&:obj_id)).to_not include @deleted_workspace.obj_id
    end
  end

  describe '7 - Subsequent Rollout' do
    before(:all) do
      @config_template_path = File.expand_path(
        '../params/rollout_brick.json.erb',
        __FILE__
      )
    end

    include_context 'rollout brick'

    it_behaves_like 'a synchronization brick' do
      let(:original_project) { $master }
      let(:projects) { $client_projects }
      let(:schedules_status) { 'ENABLED' }
      let(:lcm_managed_tag) { true }
      let(:update_operations) do
        [
          {
            'updateOperation' => {
              'type' => 'dataset.drop',
              'dataset' => 'dataset.quotes',
              'destructive' => true,
              'description' => "Drop dataset '%s'",
              'parameters' => ['Stock Quotes Data']
            }
          }
        ]
      end
      let(:update_scripts) do
        [
          {
            'updateScript' => {
              'maqlDdl' => "DROP ALL IN {dataset.quotes} CASCADE;\n",
              'maqlDdlChunks' => ["DROP ALL IN {dataset.quotes} CASCADE;\n"],
              'preserveData' => true,
              'cascadeDrops' => true
            }
          },
          {
            'updateScript' => {
              'maqlDdl' => "DROP ALL IN {dataset.quotes} CASCADE;\n",
              'maqlDdlChunks' => ["DROP ALL IN {dataset.quotes} CASCADE;\n"],
              'preserveData' => false,
              'cascadeDrops' => true
            }
          }
        ]
      end
      let(:client_id_schedule_parameter) { true }
      let(:user_group) { false }
      let(:schedule_diff) do
        [['+', 'hiddenParams.hidden_msg_from_rollout_brick', nil],
         ['+', 'params.msg_from_rollout_brick', 'Hi, I was set by rollout brick']]
      end
    end
  end
end
