# encoding: utf-8

require 'fileutils'
require 'multi_json'

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

        # Try read token
        #
        # Tries to read it from ~/.gooddata file or from environment variable GD_PROJECT_TOKEN
        # @param [String] credentials_file_path (credentials_file) Path to .gooddata file
        # @return [String] auth token from .gooddata, environment variable or nil
        def read_token(credentials_file_path = credentials_file)
          goodfile = read_credentials(credentials_file_path)
          goodfile[:auth_token] || goodfile[:token] || ENV['GD_PROJECT_TOKEN']
        end

        # Writes credentials
        def write_credentials(credentials, credentials_file_path = credentials_file)
          File.open(credentials_file_path, 'w', 0600) do |f|
            f.puts MultiJson.encode(credentials, :pretty => true)
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
