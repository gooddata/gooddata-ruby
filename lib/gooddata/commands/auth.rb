# encoding: UTF-8

require 'highline/import'
require 'multi_json'

require_relative '../cli/terminal'
require_relative '../helpers'

module GoodData::Command
  class Auth
    class << self
      # Get path of .gooddata config
      def credentials_file
        "#{GoodData::Helpers.home_directory}/.gooddata"
      end

      # Ask for credentials
      def ask_for_credentials
        puts 'Enter your GoodData credentials.'
        user = GoodData::CLI.terminal.ask('Email')
        password = GoodData::CLI.terminal.ask('Password') { |q| q.echo = 'x' }
        auth_token = GoodData::CLI.terminal.ask('Authorization Token')

        { :username => user, :password => password, :auth_token => auth_token }
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

      # Writes credentials
      def write_credentials(credentials, credentials_file_path = credentials_file)
        File.open(credentials_file_path, 'w', 0600) do |f|
          f.puts MultiJson.encode(credentials, :pretty => true)
        end
        credentials
      end

      # Ask for credentials and store them
      def store(credentials_file_path = credentials_file)
        credentials = ask_for_credentials

        ovewrite = if File.exist?(credentials_file_path)
                     GoodData::CLI.terminal.ask('Overwrite existing stored credentials (y/n)')
                   else
                     'y'
                   end

        if ovewrite == 'y'
          write_credentials(credentials, credentials_file_path)
        else
          puts 'Aborting...'
        end
      end

      # Delete stored credentials
      def unstore(credentials_file_path = credentials_file)
        FileUtils.rm_f(credentials_file_path)
      end
    end
  end
end
