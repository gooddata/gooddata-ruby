require_relative '../fixtures/user_provisioning_fixtures'
require_relative '../userprov/support/user_provisioning_helper'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/support/s3_helper'


describe GoodData::SplunkLoggerDecorator do
  context 'when splunk logging is switched on' do
    it 'logs stuff into the expected file' do
      params = {
        "SPLUNK_LOGGING" => "true"
      }

      expect { GoodData::Bricks::Pipeline.help_brick_pipeline.call params }.to output(/component=lcm\.ruby/).to_stdout_from_any_process
      expect(GoodData.gd_logger.logging_on?(:splunk)).to be_truthy
      # TODO: verify that messages passed to GoodData.logger are also included
    end
  end
end
