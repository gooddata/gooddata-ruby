# encoding: utf-8

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
        # @return [String] server token from .gooddata, environment variable or nil
        def read_environment(credentials_file_path = credentials_file)
          goodfile = read_credentials(credentials_file_path)
          [goodfile[:environment], ENV['GD_ENVIRONMENT'], GoodData::Project::DEFAULT_ENVIRONMENT].find { |x| !x.nil? && !x.empty? }
        end

        # Try read server
        #
        # Tries to read it from ~/.gooddata file or from environment variable GD_SERVER
        # @param [String] credentials_file_path (credentials_file) Path to .gooddata file
        # @return [String] server token from .gooddata, environment variable or DEFAULT_URL
        def read_server(credentials_file_path = credentials_file)
          goodfile = read_credentials(credentials_file_path)
          [goodfile[:server], ENV['GD_SERVER'], GoodData::Rest::Connection::DEFAULT_URL].find { |x| !x.nil? && !x.empty? }
        end

        # Try read token
        #
        # Tries to read it from ~/.gooddata file or from environment variable GD_PROJECT_TOKEN
        # @param [String] credentials_file_path (credentials_file) Path to .gooddata file
        # @return [String] auth token from .gooddata, environment variable or nil
        def read_token(credentials_file_path = credentials_file)
          goodfile = read_credentials(credentials_file_path)
          [goodfile[:auth_token],  goodfile[:token], ENV['GD_PROJECT_TOKEN']].find { |x| !x.nil? && !x.empty? }
        end

        # Writes credentials
        def write_credentials(credentials, credentials_file_path = credentials_file)
          File.open(credentials_file_path, 'w', 0600) do |f|
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
