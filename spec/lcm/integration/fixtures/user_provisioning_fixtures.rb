require_relative '../support/user_provisioning_helper'
require_relative '../support/configuration_helper'
require_relative '../support/connection_helper'
require_relative '../support/s3_helper'
require_relative '../support/lcm_helper'
require_relative '../support/project_helper'
require_relative 'base_fixtures'
require_relative 'project_fixtures'

module Fixtures
  class UserProvisioningFixtures < BaseFixtures
    FIXTURE_ID_PREFIX += 'userprov-e2e-'

    def initialize(opts = {})
      user_amount = opts[:user_amount] || 2
      rest_client = LcmConnectionHelper.production_server_connection
      domain = rest_client.domain(LcmConnectionHelper.environment[:prod_organization])

      users = Array.new(user_amount) do |n|
        {
          custom_login: "lcm-userprov-e2e-UPPERCASE-#{n}@gooddata.com",
          position: 'developer'
        }
      end

      project_fixtures = ProjectFixtures.new domain: domain, rest_client: rest_client, project_amount: 2

      user_data = project_fixtures[:clients].map do |c, p|
        users.map do |u|
          u.merge client_id: c.client_id,
                  project_id: p.pid
        end
      end.flatten

      Support::S3Helper.upload_file(ConfigurationHelper.csv_from_hashes(user_data), Support::S3Helper::USERS_KEY)
      users.map do |u|
        domain.add_user(login: u[:custom_login]) unless domain.users u[:custom_login]
      end

      mufs = project_fixtures[:clients].map do |client, project|
        Support::UserProvisioningHelper.muf_data client: client, project: project, users: users
      end.flatten
      Support::S3Helper.upload_file(ConfigurationHelper.csv_from_hashes(mufs), Support::S3Helper::USER_FILTERS_KEY)

      brick_params = {
        project_id: project_fixtures[:projects].first.pid, # this doesn't really matter for the runtime
        config: LcmConnectionHelper.environment,
        s3_bucket: Support::S3Helper::BUCKET_NAME,
        s3_endpoint: Support::S3Helper::S3_ENDPOINT,
        s3_key: Support::S3Helper::USER_FILTERS_KEY,
        data_source: 's3',
        column_name: 'value',
        sync_mode: 'sync_domain_client_workspaces',
        label_config: Support::UserProvisioningHelper.label_config(mufs).to_json,
        data_product: project_fixtures[:data_product].data_product_id,
        users_brick_input: {
          s3_bucket: Support::S3Helper::BUCKET_NAME,
          s3_endpoint: Support::S3Helper::S3_ENDPOINT,
          s3_key: Support::S3Helper::USERS_KEY
        }
      }

      # consider joining brick_params and the rest in the future!
      @objects = {
        brick_params: brick_params,
        projects: project_fixtures[:projects],
        mufs: mufs,
        user_data: user_data,
        users: users,
        domain: domain,
        rest_client: rest_client,
        clients: project_fixtures[:clients]
      }
    end
  end
end
