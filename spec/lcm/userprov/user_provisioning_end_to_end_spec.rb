require_relative '../integration/fixtures/user_provisioning_fixtures'
require_relative '../integration/support/user_provisioning_helper'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/support/s3_helper'

describe 'the user provisioning flow' do
  before(:all) do
    @fixtures = Fixtures::UserProvisioningFixtures.new projects_amount: 2,
                                             user_amount: 2
  end

  after(:all) do
    @fixtures.teardown
  end

  describe '1 - initial MUF setup' do
    it 'provisions MUFs' do
      Support::UserProvisioningHelper.test_user_filters_brick(projects: @fixtures[:projects],
                              test_context: @fixtures[:brick_params],
                              mufs: @fixtures[:mufs])
    end
  end

  describe '2 - initial user setup' do
    it 'provisions users' do
      Support::UserProvisioningHelper.test_users_brick(projects: @fixtures[:projects],
                       test_context: @fixtures[:brick_params],
                       user_data: @fixtures[:user_data])
    end
  end

  describe '3 - subsequent user setup after modification' do
    it 'provisions users' do
      user_data = @fixtures[:user_data].map do |c|
        c.merge('position' => 'manager')
      end
      Support::S3Helper.upload_file(ConfigurationHelper.csv_from_hashes(user_data), Support::S3Helper::USERS_KEY)
      Support::UserProvisioningHelper.test_users_brick(projects: @fixtures[:projects],
                       test_context: @fixtures[:brick_params],
                       user_data: user_data)
    end
  end

  describe '4 - subsequent MUF setup after modification' do
    it 'provisions MUFs' do
      mufs = @fixtures[:clients].map do |client, project|
        Support::UserProvisioningHelper.muf_data client: client, project: project, users: @fixtures[:users], muf_complexity: 4
      end.flatten
      Support::S3Helper.upload_file(ConfigurationHelper.csv_from_hashes(mufs), Support::S3Helper::USER_FILTERS_KEY)

      params = @fixtures[:brick_params]
      params[:label_config] = [JSON.parse(params[:label_config], symbolize_names: true).first.merge(label: mufs.first[:label_id])].to_json
      Support::UserProvisioningHelper.test_user_filters_brick(projects: @fixtures[:projects],
                              test_context: params,
                              mufs: mufs)
    end
  end
end
