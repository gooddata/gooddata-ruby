require_relative '../fixtures/user_provisioning_fixtures'
require_relative '../userprov/support/user_provisioning_helper'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/support/s3_helper'

file_name = nil

describe GoodData::SplunkLogger do
  before(:all) do
    @fixtures = Fixtures::UserProvisioningFixtures.new projects_amount: 2,
                                                       user_amount: 2
  end
  context 'when splunk logging is switched off' do
    it 'does not log to splunk' do
      params = @fixtures[:brick_params].merge(splunk_logging: false)
      Support::UserProvisioningHelper.test_users_brick(projects: @fixtures[:projects],
                                                       test_context: params,
                                                       user_data: @fixtures[:user_data])
      expect(GoodData.gd_logger.logging_on?(:splunk)).to be_falsey
    end
  end

  context 'when splunk logging is switched on' do
    before do
      file_name = "splunk_#{GoodData::Environment::RANDOM_STRING}.log"
    end

    after(:all) do
      File.delete file_name if File.exist? file_name
    end

    it 'logs stuff into the expected file' do
      params = @fixtures[:brick_params].merge(
        splunk_logging: true,
        splunk_log_path: file_name
      )
      Support::UserProvisioningHelper.test_users_brick(projects: @fixtures[:projects],
                                                       test_context: params,
                                                       user_data: @fixtures[:user_data])

      expect(GoodData.gd_logger.logging_on?(:splunk)).to be_truthy
      contents = File.read(file_name)

      expect(contents).to include 'component=lcm.ruby'
      expect(contents).to include 'INFO'
      # TODO: verify that messages passed to GoodData.logger are also included
    end
  end
end
