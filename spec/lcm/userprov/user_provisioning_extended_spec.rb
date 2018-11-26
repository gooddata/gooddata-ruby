require_relative '../fixtures/user_provisioning_fixtures'
require_relative 'support/user_provisioning_helper'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/support/s3_helper'
require_relative '../../../lib/gooddata/models/user_filters/user_filter_builder'
require_relative '../../../lib/gooddata/lcm/lcm2'

describe 'the extended user provisioning functionality' do
  before(:all) do
    @fixtures = Fixtures::UserProvisioningFixtures.new projects_amount: 2,
                                                       user_amount: 2
  end

  after(:all) do
    @fixtures.teardown
  end

  describe 'when provisioning in the declarative mode' do
    it 'removes MUFs from projects not mentioned in the input' do
      Support::UserProvisioningHelper.test_users_brick(projects: @fixtures[:projects],
                                                       test_context: @fixtures[:brick_params],
                                                       user_data: @fixtures[:user_data])
      Support::UserProvisioningHelper.test_user_filters_brick(projects: @fixtures[:projects],
                                                              test_context: @fixtures[:brick_params],
                                                              mufs: @fixtures[:mufs])

      extra_project = @fixtures[:projects].first
      mufs = @fixtures[:mufs].reject { |m| m[:project_id] == extra_project.pid }
      Support::UserProvisioningHelper.upload_mufs(mufs)

      Support::UserProvisioningHelper.test_user_filters_brick(projects: @fixtures[:projects],
                                                              test_context: @fixtures[:brick_params],
                                                              mufs: mufs)
    end
  end
end
