require_relative '../fixtures/user_provisioning_fixtures'
require_relative '../userprov/support/user_provisioning_helper'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/support/s3_helper'

file_name = nil

describe GoodData::SplunkLoggerDecorator do
  context 'when splunk logging is switched on' do
    before do
      file_name = "splunk_#{GoodData::Environment::RANDOM_STRING}.log"
    end

    after(:all) do
      File.delete file_name if File.exist? file_name
    end

    it 'logs stuff into the expected file' do
      params = {
        "SPLUNK_LOGGING" => "true",
        "SPLUNK_LOG_PATH" => file_name
      }

      GoodData::Bricks::Pipeline.help_brick_pipeline.call params
      expect(GoodData.gd_logger.logging_on?(:splunk)).to be_truthy
      contents = File.read(file_name)

      expect(contents).to include 'component=lcm.ruby'
      expect(contents).to include 'INFO'
      # TODO: verify that messages passed to GoodData.logger are also included
    end
  end
end
