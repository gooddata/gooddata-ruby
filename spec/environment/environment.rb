# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
require 'yaml'
require 'active_support/core_ext/hash/keys'

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
        env_secrets = decrypt_secrets(env)
        GoodData::Environment::ConnectionHelper.set_const('SECRETS', env_secrets)
        GoodData::Environment::ProjectHelper.set_const :PROJECT_URL, "/gdc/projects/#{GoodData::Environment::ProjectHelper::PROJECT_ID}"
        ENV['GD_SERVER'] = GoodData::Environment::ConnectionHelper::DEFAULT_SERVER
        # VCR is enabled by default - set VCR_ON=false to disable
        vcr_on = ENV['VCR_ON'].nil? || ENV['VCR_ON'].downcase == 'true'
        GoodData::Environment.set_const(:VCR_ON, vcr_on)
      end

      private

      # Translates ci-infra branch to environment config name
      # @param branch Name of the branch we are testing against
      def branch_to_environment(branch)
        BRANCH_TO_ENVIRONMENT[branch.to_sym] || branch
      end

      def decrypt_secrets(env)
        secrets_path = File.join(File.dirname(__FILE__), 'secrets.yaml')
        secrets = YAML.load_file(secrets_path)
        env_secrets = secrets[env.downcase].symbolize_keys
        encryption_key = ENV['GD_SPEC_PASSWORD'] || ENV['BIA_ENCRYPTION_KEY']
        env_secrets.each do |_, value|
          decrypted = GoodData::Helpers.decrypt(value, encryption_key)
          value.replace(decrypted)
        end
      end
    end
  end
end
