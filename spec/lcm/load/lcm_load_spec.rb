require 'aws-sdk-s3'
require 'tempfile'
require 'csv'
require 'active_support/core_ext/numeric/time'

require_relative '../integration/support/constants'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/spec/shared_examples_for_synchronization_bricks'
require_relative '../integration/spec/shared_contexts_for_lcm'
require_relative '../integration/spec/brick_runner'
require_relative '../helpers/schedule_helper'
require_relative 'shared_contexts_for_load_tests'

# set up by execmgr-k8s
image_tag = ENV['LCM_BRICKS_IMAGE_TAG']
# global variables to simplify passing stuff between shared contexts and examples
$segments_multiplier = ENV['GD_LCM_SPEC_SEGMENTS_MULTIPLIER'] ? ENV['GD_LCM_SPEC_SEGMENTS_MULTIPLIER'].to_i : 2
$workspaces_multiplier = ENV['GD_LCM_SPEC_WORKSPACES_MULTIPLIER'] ? ENV['GD_LCM_SPEC_WORKSPACES_MULTIPLIER'].to_i : 1000
$master_projects = []
$client_projects = []
service_project = nil
release_schedule = nil
provisioning_schedule = nil
rollout_schedule = nil

GoodData::Environment.const_set('VCR_ON', false)

describe 'LCM load test' do
  include_context 'lcm bricks'
  include_context 'load tests cleanup' unless ENV['GD_LCM_SMOKE_TEST'] == 'true'

  describe 'release/provisioning/rollout' do
    xit 'schedules bricks' do
      service_project = @prod_rest_client.create_project(
        title: 'lcm load test service project',
        auth_token: @test_context[:config][:prod_token]
      )

      release_schedule = BrickRunner.schedule_brick(
        'release_brick',
        service_project,
        context: @test_context,
        image_tag: image_tag
      )

      provisioning_schedule = BrickRunner.schedule_brick(
        'provisioning_brick',
        service_project,
        context: @test_context,
        run_after: release_schedule,
        image_tag: image_tag
      )

      rollout_schedule = BrickRunner.schedule_brick(
        'rollout_brick',
        service_project,
        context: @test_context,
        run_after: provisioning_schedule,
        image_tag: image_tag
      )

      release_schedule.execute(wait: false)
    end

    xit 'successfully finishes' do
      timeout = 3.hours
      results = GoodData::AppStore::Helper.wait_for_executions([release_schedule, provisioning_schedule, rollout_schedule], timeout)
      results.each do |result|
        expect(result.status).to be :ok
      end
    end
  end
end
