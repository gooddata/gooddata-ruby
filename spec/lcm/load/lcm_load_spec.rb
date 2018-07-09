require 'gooddata_datawarehouse'
require 'aws-sdk-s3'
require 'tempfile'
require 'csv'

require_relative '../integration/support/constants'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/shared_examples_for_synchronization_bricks'
require_relative '../integration/shared_contexts_for_lcm_specs'

# global variables to simplify passing stuff between shared contexts and examples
$master_projects = []
$client_projects = []
$master = false

$segments_multiplier = ENV['GD_LCM_SEGMENTS_MULTIPLIER'] || 2
$workspaces_multiplier = ENV['GD_LCM_WORKSPACES_MULTIPLIER'] || 100

describe 'LCM load test' do
  include_context 'lcm bricks'

  before(:all) do
    @start_time = Time.now
  end

  after(:all) do
    duration = Time.now - @start_time
    puts '=' * 10
    puts "The run took #{duration} seconds"
    puts "Out of that, release took #{@release_time} s, provisioning took #{@provisioning_time} s, rollout took #{@rollout_time} s"
  end

  describe 'release' do
    include_context 'release brick'
    after(:all) do
      @release_time = Time.now - @start_time
    end
    # these need to be in every describe to ensure the before and after hooks (which contain the brick run) happen
    it('does not fail') {}
  end

  describe 'provisioning' do
    include_context 'provisioning brick'
    after(:all) do
      @provisioning_time = Time.now - @start_time
    end
    it('does not fail') {}
  end

  describe 'rollout' do
    include_context 'rollout brick'
    after(:all) do
      @rollout_time = Time.now - @start_time
    end
    it('does not fail') {}
  end
end
