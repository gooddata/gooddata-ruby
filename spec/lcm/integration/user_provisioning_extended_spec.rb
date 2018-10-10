require_relative 'fixtures/user_provisioning_fixtures'
require_relative 'support/user_provisioning_helper'
require_relative 'support/configuration_helper'
require_relative 'support/s3_helper'
require_relative '../../../lib/gooddata/models/user_filters/user_filter_builder'
require_relative '../../../lib/gooddata/lcm/lcm2'

describe 'the extended user provisioning functionality' do
  before(:all) do
    @fixtures = Fixtures::UserProvisioningFixtures.new projects_amount: 2,
                                                       user_amount: 2
    @project_fixtures = Fixtures::ProjectFixtures.new rest_client: @fixtures[:rest_client], domain: @fixtures[:domain]
  end

  after(:all) do
    @fixtures.teardown
    @project_fixtures.teardown
  end

  describe 'when provisioning in the declarative mode' do
    it 'removes MUFs from projects not mentioned in the input' do
      extra_client, extra_project = @project_fixtures[:clients].first
      extra_mufs = Support::UserProvisioningHelper.muf_data client: extra_client, project: extra_project, users: @fixtures[:users]
      builder_config = {
        user_column: 'login',
        labels: [
          {
            column: 'value',
            label: extra_mufs.first[:label_id]
          }
        ]
      }
      extra_project.add_data_permissions GoodData::UserFilterBuilder.get_filters(GoodData::LCM2.convert_to_smart_hash(extra_mufs),
                                                                                 GoodData::LCM2.convert_to_smart_hash(builder_config))

      mufs = @project_fixtures[:clients].map do |client, project|
        Support::UserProvisioningHelper.muf_data client: client, project: project, users: @fixtures[:users], muf_complexity: 4
      end.flatten
      Support::S3Helper.upload_file(ConfigurationHelper.csv_from_hashes(mufs), Support::S3Helper::USER_FILTERS_KEY)
      label_config = Support::UserProvisioningHelper.label_config(mufs).to_json
      params = @fixtures[:brick_params].merge(label_config: label_config)

      Support::UserProvisioningHelper.test_user_filters_brick(projects: @fixtures[:projects] + [extra_project],
                                                              test_context: params,
                                                              mufs: @fixtures[:mufs])
    end
  end
end
