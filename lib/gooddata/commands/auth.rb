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

        {:username => user, :password => password, :auth_token => auth_token}
      end

      # Ask for credentials and store them
      def store
        credentials = ask_for_credentials

        ovewrite = if File.exist?(credentials_file)
                     GoodData::CLI.terminal.ask("Overwrite existing stored credentials (y/n)")
                   else
                     'y'
                   end

        if ovewrite == 'y'
          File.open(credentials_file, 'w', 0600) do |f|
            f.puts JSON.pretty_generate(credentials)
          end
        else
          puts 'Aborting...'
        end
      end

      # Delete stored credentials
      def unstore
        FileUtils.rm_f(credentials_file)
      end
    end
  end
end
