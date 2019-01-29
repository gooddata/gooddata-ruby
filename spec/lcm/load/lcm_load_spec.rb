require 'gooddata_datawarehouse'
require 'aws-sdk-s3'
require 'tempfile'
require 'csv'

require_relative '../integration/support/constants'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/shared_examples_for_synchronization_bricks'
require_relative '../integration/shared_contexts_for_lcm'
require_relative '../integration/brick_runner'
require_relative 'shared_contexts_for_load_tests'

# global variables to simplify passing stuff between shared contexts and examples
$segments_multiplier = ENV['GD_LCM_SEGMENTS_MULTIPLIER'] || 2
$workspaces_multiplier = ENV['GD_LCM_WORKSPACES_MULTIPLIER'] || 100
$master_projects = []
$client_projects = []
service_project = nil
release_schedule = nil
provisioning_schedule = nil
rollout_schedule = nil

describe 'LCM load test' do
  include_context 'lcm bricks'
  include_context 'load tests'

  describe 'release/provisioning/rollout' do
    it 'schedules bricks' do
      service_project = @prod_rest_client.create_project(
        title: 'lcm load test service project',
        auth_token: @test_context[:config][:prod_token]
      )

      release_schedule = BrickRunner.schedule_brick(
        'release_brick',
        service_project,
        context: @test_context
      )

      provisioning_schedule = BrickRunner.schedule_brick(
        'provisioning_brick',
        service_project,
        context: @test_context,
        run_after: release_schedule
      )

      rollout_schedule = BrickRunner.schedule_brick(
        'rollout_brick',
        service_project,
        context: @test_context,
        run_after: provisioning_schedule
      )

      release_schedule.execute(wait: false)
    end

    it 'successfully finishes' do
      timeout = 3.hours
      results = GoodData::AppStore::Helper.wait_for_executions([release_schedule, provisioning_schedule, rollout_schedule], timeout)
      results.each do |result|
        expect(result.status).to be :ok
      end
    end
  end
end
