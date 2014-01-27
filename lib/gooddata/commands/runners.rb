require 'bundler'

module GoodData::Command
  class Runners

    def self.run_ruby_locally(brick_dir, options={})
      pid = options[:project]
      fail "You have to specify a project ID" if pid.nil?
      fail "You have to specify directory of the brick run" if brick_dir.nil?
      fail "You specified file as a birck run directory. You have to specify directory." if File.exist?(brick_dir) && !File.directory?(brick_dir)

      params = if options[:params]
        JSON.parse(File.read(options[:params]), :symbolize_names => true)
      else
        {}
      end

      GoodData.connection.connect!
      sst = GoodData.connection.cookies[:cookies]["GDCAuthSST"]
      pwd = Pathname.new(Dir.pwd)
      logger_stream = STDOUT

script_body = <<-script_body
      require 'fileutils'
      FileUtils::cd(\"#{pwd+brick_dir}\") do\
        require 'bundler/setup'
        eval(File.read(\"main.rb\")).call({
          :GDC_SST => \"#{sst}\",
          :GDC_PROJECT_ID => \"#{pid}\"
        }.merge(#{params}))
      end
script_body

      Bundler.with_clean_env do
        system("ruby", "-e", script_body)  
      end
    end

  end
end