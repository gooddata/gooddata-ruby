module GoodData::Command
  class Runners

    def self.run_ruby(brick_dir, options={})
      pid = options[:project]
      fail "You have to specify a project ID" if pid.nil?
      fail "You have to specify directory of the brick ran" if brick_dir.nil?

      params = if options[:params]
        JSON.parse(File.read(options[:params]), :symbolize_names => true)
      else
        {}
      end

      GoodData.connection.connect!
      sst = GoodData.connection.cookies[:cookies]["GDCAuthSST"]
      
      logger_stream = STDOUT
script_body = <<-script_body
      require 'fileutils'
      FileUtils::cd(\"#{brick_dir}\") do\
        require 'bundler/setup'
        eval(File.read(\"main.rb\")).call({
          :gdc_sst => \"#{sst}\",
          :gdc_project => \"#{pid}\"
        }.merge(#{params}))
      end
script_body


      Bundler.with_clean_env do
        system("ruby", "-e", script_body)  
      end
    end

  end
end