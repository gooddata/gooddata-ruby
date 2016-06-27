# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'fileutils'
require 'json'

require_relative 'global_helpers'

module GoodData
  module Helpers
    module AuthHelper
      class << self
        # Get path of .gooddata config
        def credentials_file
          "#{Helpers.home_directory}/.gooddata"
        end

        # Read credentials
        def read_credentials(credentials_file_path = credentials_file)
          if File.exist?(credentials_file_path)
            config = File.read(credentials_file_path)
            MultiJson.load(config, :symbolize_keys => true)
          else
            {}
          end
        end

        # Try read environemnt
        #
        # Tries to read it from ~/.gooddata file or from environment variable GD_SERVER
        # @param [String] credentials_file_path (credentials_file) Path to .gooddata file
        # @return [String] server token from environment variable, .gooddata or nil
        def read_environment(credentials_file_path = credentials_file)
          goodfile = read_credentials(credentials_file_path)
          [ENV['GD_ENVIRONMENT'], goodfile[:environment], GoodData::Project::DEFAULT_ENVIRONMENT].find { |x| !x.nil? && !x.empty? }
        end

        # Try read server
        #
        # Tries to read it from ~/.gooddata file or from environment variable GD_SERVER
        # @param [String] credentials_file_path (credentials_file) Path to .gooddata file
        # @return [String] server token from environment variable, .gooddata or DEFAULT_URL
        def read_server(credentials_file_path = credentials_file)
          goodfile = read_credentials(credentials_file_path)
          [ENV['GD_SERVER'], goodfile[:server], GoodData::Rest::Connection::DEFAULT_URL].find { |x| !x.nil? && !x.empty? }
        end

        # Try read token
        #
        # Tries to read it from ~/.gooddata file or from environment variable GD_PROJECT_TOKEN
        # @param [String] credentials_file_path (credentials_file) Path to .gooddata file
        # @return [String] auth token from environment variable, .gooddata or nil
        def read_token(credentials_file_path = credentials_file)
          goodfile = read_credentials(credentials_file_path)
          [ENV['GD_PROJECT_TOKEN'], goodfile[:auth_token], goodfile[:token]].find { |x| !x.nil? && !x.empty? }
        end

        # Writes credentials
        def write_credentials(credentials, credentials_file_path = credentials_file)
          File.open(credentials_file_path, 'w', 0o600) do |f|
            f.puts JSON.pretty_generate(credentials)
          end
          credentials
        end

        def remove_credentials_file(credentials_file_path = credentials_file)
          FileUtils.rm_f(credentials_file_path)
        end
      end
    end
  end
end
