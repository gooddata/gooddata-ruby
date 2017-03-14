# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    class << self
      BRANCH_TO_ENVIRONMENT = {
        develop: 'testing',
        hotfix: 'production'
      }

      def load(env = ENV['GD_ENV'] || 'development')
        require_relative 'default'
        env = branch_to_environment(env)

        puts "USING ENVIRONMENT: #{env}"
        begin
          require_relative env
        rescue
          puts "Unable to find environment '#{env}'"
          require_relative 'development'
        end

        GoodData::Environment::ProjectHelper.set_const :PROJECT_URL, "/gdc/projects/#{GoodData::Environment::ProjectHelper::PROJECT_ID}"
        ENV['GD_SERVER'] = GoodData::Environment::ConnectionHelper::DEFAULT_SERVER
      end

      # Translates ci-infra branch to environment config name
      # @param branch Name of the branch we are testing against
      def branch_to_environment(branch)
        BRANCH_TO_ENVIRONMENT[branch.to_sym] || branch
      end
    end
  end
end
