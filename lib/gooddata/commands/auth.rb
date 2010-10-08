module Gooddata::Command
  class Auth < Base
    def client
      unless @client
        log_level = extract_option('--log-level', :warn)
        raise InvalidOption, "Unknown log level '#{log_level}'" unless %w(fatal error warn info debug).include?(log_level)
        @client = Gooddata::Client.new(user, password, log_level.to_sym)
      end
      @client
    end

    def user
      ensure_credentials
      @credentials[0]
    end

    def password
      ensure_credentials
      @credentials[1]
    end

    def credentials_file
      "#{home_directory}/.gooddata"
    end

    def ensure_credentials
      return if @credentials
      unless @credentials = read_credentials
        @credentials = ask_for_credentials
      end
      @credentials
    end

    def read_credentials
      File.exists?(credentials_file) and File.read(credentials_file).split("\n")
    end

    def ask_for_credentials
      puts "Enter your GoodData credentials."
      user = ask("Email")
      passowrd = ask("Password", :secret => true)
      [ user, password ]
    end

    def store
      credentials = ask_for_credentials

      ovewrite = if File.exist?(credentials_file)
        ask "Overwrite existing stored credentials", :answers => %w(y n)
      else
        'y'
      end

      if ovewrite == 'y'
        File.open(credentials_file, 'w', 0600) do |f|
          f.puts credentials
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