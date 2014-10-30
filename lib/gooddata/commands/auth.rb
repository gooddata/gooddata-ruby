# encoding: UTF-8

require 'highline/import'

require_relative '../cli/terminal'
require_relative '../helpers/helpers'

module GoodData
  module Command
    class Auth
      class << self
        # Ask for credentials
        def ask_for_credentials
          puts 'Enter your GoodData credentials.'
          user = GoodData::CLI.terminal.ask('Email')
          password = GoodData::CLI.terminal.ask('Password') { |q| q.echo = 'x' }
          auth_token = GoodData::CLI.terminal.ask('Authorization Token')

          { :username => user, :password => password, :auth_token => auth_token }
        end

        # Ask for credentials and store them
        def store(credentials_file_path = Helpers::AuthHelper.credentials_file)
          credentials = ask_for_credentials

          ovewrite = if File.exist?(credentials_file_path)
                       GoodData::CLI.terminal.ask('Overwrite existing stored credentials (y/n)')
                     else
                       'y'
                     end

          if ovewrite == 'y'
            Helpers::AuthHelper.write_credentials(credentials, credentials_file_path)
          else
            puts 'Aborting...'
          end
        end

        # Delete stored credentials
        def unstore(credentials_file_path = Helpers::AuthHelper.credentials_file)
          Helpers::AuthHelper.remove_credentials_file(credentials_file_path)
        end
      end
    end
  end
end
