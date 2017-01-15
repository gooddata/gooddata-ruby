# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    class << self
      def load(env = (ENV['GD_ENV'] && ENV['GD_ENV'].split('/')[1]) || 'develop')
        require_relative 'default'

        puts "USING ENVIRONMENT: #{env}"
        begin
          require_relative env
        rescue
          puts "Unable to find environment '#{env}'"
          require_relative 'develop'
        end

        GoodData::Environment::ProjectHelper.set_const :PROJECT_URL, "/gdc/projects/#{GoodData::Environment::ProjectHelper::PROJECT_ID}"
        ENV['GD_SERVER'] = GoodData::Environment::ConnectionHelper::DEFAULT_SERVER
      end
    end
  end
end
