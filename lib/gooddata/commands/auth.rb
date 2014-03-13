require 'json'

require File.join(File.dirname(__FILE__), '../helpers')

module GoodData::Command
  class Auth
    
    class << self
      def connect
        unless defined? @connected
          GoodData.connect({
            :login    => user,
            :password => password,
            :server   => url,
            :auth_token => auth_token
          })
          @connected = true
        end
        @connected
      end

      def user
        ensure_credentials
        @credentials[:username]
      end

      def password
        ensure_credentials
        @credentials[:password]
      end

      def url
        ensure_credentials
        @credentials[:url]
      end

      def auth_token
        ensure_credentials
        @credentials[:auth_token]
      end

      def credentials_file
        "#{GoodData::Helpers.home_directory}/.gooddata"
      end

      def ensure_credentials
        return if defined? @credentials
        unless @credentials = read_credentials
          @credentials = ask_for_credentials
        end
        @credentials
      end

      def read_credentials
        if File.exists?(credentials_file) then
          config = File.read(credentials_file)
          JSON.parser.new(config, :symbolize_names => true).parse
        else
          {}
        end
      end

      def ask_for_credentials
        puts "Enter your GoodData credentials."
        user = HighLine::ask("Email")
        password = HighLine::ask("Password") { |q| q.echo = "x" }
        auth_token = HighLine::ask("Authorization Token")
        { :username => user, :password => password, :auth_token => auth_token }
      end

      def store
        credentials = ask_for_credentials

        ovewrite = if File.exist?(credentials_file)
          HighLine::ask("Overwrite existing stored credentials (y/n)")
           # { |q| q.validate = /[y,n]/ }
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

      def unstore
        FileUtils.rm_f(credentials_file)
      end
    end
  end
end
