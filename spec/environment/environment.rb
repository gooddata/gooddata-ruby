# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
require 'yaml'
require 'active_support/core_ext/hash/keys'
require 'securerandom'

module GoodData
  module Environment
    class << self
      BRANCH_TO_ENVIRONMENT = {
        develop: 'testing',
        hotfix: 'production'
      }

      def load(env = ENV['GD_ENV'] || 'testing')
        require_relative 'default'
        env = branch_to_environment(env)
        puts "USING ENVIRONMENT: #{env}"
        require_relative env
        env_secrets = initial_secrets(env)
        GoodData::Environment::ConnectionHelper.set_const('SECRETS', env_secrets)
        ENV['GD_SERVER'] = GoodData::Environment::ConnectionHelper::DEFAULT_SERVER
        # VCR is enabled by default - set VCR_ON=false to disable
        vcr_on = ENV['VCR_ON'].nil? || ENV['VCR_ON'].downcase == 'true'
        GoodData::Environment.set_const(:VCR_ON, vcr_on)
        suffix = SecureRandom.urlsafe_base64(5).gsub('-', '_')
        GoodData::Environment.set_const(:RANDOM_STRING, suffix)
      end

      private

      # Translates ci-infra branch to environment config name
      # @param branch Name of the branch we are testing against
      def branch_to_environment(branch)
        BRANCH_TO_ENVIRONMENT[branch.to_sym] || branch
      end

      def initial_secrets(env)
        key_prefix = if env == 'development' then
                       'GD_DEV'
                     else
                       # env == 'testing' is also utilizing staging1
                       'GD_STG'
                     end
        {
          s3_bucket_name: ENV['RT_S3_BUCKET_NAME'],
          s3_access_key_id: ENV['RT_S3_ACCESS_KEY'],
          s3_secret_access_key: ENV['RT_S3_SECRET_KEY'],
          redshift_password: ENV['REDSHIFT_PASSWORD'],
          redshift_access_key: ENV['REDSHIFT_ACCESS_KEY'],
          redshift_secret_key: ENV['REDSHIFT_SECRET_KEY'],
          snowflake_password: ENV['SNOWFLAKE_PASSWORD'],
          blob_storage_connection: ENV['BLOB_STORAGE_CONNECTION'],
          mysql_connection: ENV['MYSQL_INTEGRATION_TEST_PASSWORD'],
          mysql_mongobi_connection: ENV['MYSQL_MONGOBI_INTEGRATION_TEST_PASSWORD'],
          dev_token: ENV["#{key_prefix}_DEV_TOKEN"],
          prod_token: ENV["#{key_prefix}_PROD_TOKEN"],
          vertica_dev_token: ENV["#{key_prefix}_VERTICA_DEV_TOKEN"],
          vertica_prod_token: ENV["#{key_prefix}_VERTICA_PROD_TOKEN"],
          password: ENV["#{key_prefix}_PASSWORD"],
          gd_project_token: ENV["#{key_prefix}_GD_PROJECT_TOKEN"],
          default_password: ENV["#{key_prefix}_DEFAULT_PASSWORD"]
        }
      end
    end
  end
end
