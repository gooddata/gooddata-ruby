# encoding: UTF-8

require 'highline/import'
require 'json'

require_relative '../cli/terminal'
require_relative '../helpers'

module GoodData::Command
  class Auth
    class << self

      # Connect to GoodData platform
      def connect
        unless defined? @connected
          GoodData.connect({
                             :login => user,
                             :password => password,
                             :server => url,
                             :auth_token => auth_token
                           })
          @connected = true
        end
        @connected
      end

      # Get credentials user
      def user
        ensure_credentials
        @credentials[:username]
      end

      # Get credentials password
      def password
        ensure_credentials
        @credentials[:password]
      end

      # Get credentials url
      def url
        ensure_credentials
        @credentials[:url]
      end

      # Get auth token from ensured credentials
      def auth_token
        ensure_credentials
        @credentials[:auth_token]
      end

      # Get path of .gooddata config
      def credentials_file
        "#{GoodData::Helpers.home_directory}/.gooddata"
      end

      # Ensure credentials existence
      def ensure_credentials
        return if defined? @credentials
        unless @credentials = read_credentials
          @credentials = ask_for_credentials
        end
        @credentials
      end

      # Read credentials
      def read_credentials
        if File.exists?(credentials_file) then
          config = File.read(credentials_file)
          JSON.parser.new(config, :symbolize_names => true).parse
        else
          {}
        end
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
