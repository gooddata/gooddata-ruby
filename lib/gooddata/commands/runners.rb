module GoodData::Command
  class Runners

    def self.run_ruby_locally(brick_dir, options={})
      pid = options[:project_id]
      fail "You have to specify a project ID" if pid.nil?
      fail "You have to specify directory of the brick run" if brick_dir.nil?
      fail "You specified file as a birck run directory. You have to specify directory." if File.exist?(brick_dir) && !File.directory?(brick_dir)

      params = options[:expanded_params] || {}

      GoodData.connection.connect!
      sst = GoodData.connection.cookies[:cookies]["GDCAuthSST"]
      pwd = Pathname.new(Dir.pwd)
      logger_stream = STDOUT

      server_uri = URI(options[:server]) unless options[:server].nil?
      scheme = server_uri.nil? ? "" : server_uri.scheme
      hostname = server_uri.nil? ? "" : server_uri.host

script_body = <<-script_body
      require 'fileutils'
      FileUtils::cd(\"#{pwd+brick_dir}\") do\
        require 'bundler/setup'

        $SCRIPT_PARAMS = {
          "GDC_SST" => \"#{sst}\",
          "GDC_PROJECT_ID" => \"#{pid}\",
          "GDC_PROTOCOL" => \"#{scheme}\",
          "GDC_HOSTNAME" => \"#{hostname}\",
          "GDC_LOGGER_FILE" => STDOUT
        }.merge(#{params})
        eval(File.read(\"./main.rb\"))
      end
script_body

      Bundler.with_clean_env do
        system("ruby", "-e", script_body)  
      end
    end

  end
end