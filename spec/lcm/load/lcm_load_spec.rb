require 'gooddata_datawarehouse'
require 'aws-sdk-s3'
require 'tempfile'
require 'csv'

require_relative '../integration/support/constants'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/shared_examples_for_synchronization_bricks'
require_relative '../integration/shared_contexts_for_lcm'
require_relative '../integration/brick_runner'

# global variables to simplify passing stuff between shared contexts and examples
$master_projects = []
$client_projects = []
$master = false
$start_time

$segments_multiplier = ENV['GD_LCM_SEGMENTS_MULTIPLIER'] || 2
$workspaces_multiplier = ENV['GD_LCM_WORKSPACES_MULTIPLIER'] || 100

describe 'LCM load test' do
  include_context 'lcm bricks'

  before(:all) do
    $start_time = Time.now
  end

  after(:all) do
    duration = Time.now - $start_time
    puts '=' * 10
    puts "The run took #{duration} seconds"
    puts "Out of that, release took #{$release_time} s, provisioning took #{$provisioning_time} s, rollout took #{$rollout_time} s"
  end

  describe 'release' do
    it 'runs' do
      BrickRunner.release_brick context: @test_context, template_path: '../../integration/params/release_brick.json.erb'
      $release_time = Time.now - $start_time
    end
  end

  describe 'provisioning' do
    it 'runs' do
      BrickRunner.provisioning_brick context: @test_context, template_path: '../../integration/params/provisioning_brick.json.erb'
      $provisioning_time = Time.now - $start_time
    end
  end

  describe 'rollout' do
    it 'runs' do
      BrickRunner.rollout_brick context: @test_context, template_path: '../../integration/params/rollout_brick.json.erb'
      $rollout_time = Time.now - $start_time
    end
  end
end
