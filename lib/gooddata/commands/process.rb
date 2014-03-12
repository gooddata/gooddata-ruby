module GoodData::Command
  class Process

    def self.list(options={})
      GoodData.with_project(options[:project_id]) do
        processes = GoodData::Process[:all]
      end
    end

    def self.get(options={})
      id = options[:process_id]
      fail "Unspecified process id" if id.nil?
      
      GoodData.with_project(options[:project_id]) do
        GoodData::Process[id]
      end
    end

    def self.deploy(dir, options={})
      verbose = options[:verbose] || false
      GoodData.with_project(options[:project_id]) do
        params = options[:params].nil? ? [] : [options[:params]]
        deploy_graph(dir, options.merge({:files_to_exclude => params}))
      end
    end

    def self.with_deploy(dir, options={}, &block) 
      verbose = options[:verbose] || false
      GoodData.with_project(options[:project_id]) do
      params = options[:params].nil? ? [] : [options[:params]]
        if block
          begin
            res = deploy_graph(dir, options.merge({:files_to_exclude => params}))
            block.call(res)
          ensure
            self_link = res && res["process"]["links"]["self"]
            GoodData.delete(self_link)
          end
        else
          deploy_graph(dir, options.merge({:files_to_exclude => params}))
        end
      end
    end

    def self.execute_process(link, dir, options={})
      dir = Pathname(dir)
      type = :ruby
      if type == :ruby 
        result = GoodData.post(link, {
          :execution => {
           :graph => ("./main.rb").to_s,
           :params => options[:expanded_params]
          }
        })
        begin
          GoodData.poll(result, "executionTask")
        rescue RestClient::RequestFailed => e

        ensure
          result = GoodData.get(result["executionTask"]["links"]["detail"])
          if result["executionDetail"]["status"] == "ERROR"
            fail "Runing process failed. You can look at a log here #{result["executionDetail"]["logFileName"]}"
          end
        end
        result
      else
        result = GoodData.post(link, {
          :execution => {
           :graph => dir + "graphs/main.grf",
           :params => {}  
          }
        })
        begin
          GoodData.poll(result, "executionTask")
        rescue RestClient::RequestFailed => e

        ensure
          result = GoodData.get(result["executionTask"]["links"]["detail"])
          if result["executionDetail"]["status"] == "ERROR"
            fail "Runing process failed. You can look at a log here #{result["executionDetail"]["logFileName"]}"
          end
        end
        result
      end
    end

    def self.run(dir, options={})
      email = options[:email]
      verbose = options[:v]
      dir = Pathname(dir)
      name = options[:name] || "Temporary deploy[#{dir}][#{options[:project_name]}]"

      with_deploy(dir, options.merge(:name => name)) do |deploy_response|
        puts HighLine::color("Executing", HighLine::BOLD) if verbose
        result = execute_process(deploy_response["process"]["links"]["executions"], dir, options)
      end
    end

    private
    def self.deploy_graph(dir, options={})
      dir = Pathname(dir) || fail("Directory is not specified")
      fail "\"#{dir}\" is not a directory" unless dir.directory?
      files_to_exclude = options[:files_to_exclude].map {|p| Pathname(p)}

      project_id = options[:project_id] || fail("Project Id has to be specified")

      type = options[:type] || "GRAPH"
      deploy_name = options[:name]
      verbose = options[:verbose] || false
      
      puts HighLine::color("Deploying #{dir}", HighLine::BOLD) if verbose
      res = nil

      Tempfile.open("deploy-graph-archive") do |temp|
        Zip::OutputStream.open(temp.path) do |zio|
          FileUtils::cd(dir) do

            files_to_pack = Dir.glob("./**/*").reject {|f| files_to_exclude.include?(Pathname(dir) + f)}
            files_to_pack.each do |item|
              puts "including #{item}" if verbose
              unless File.directory?(item)
                zio.put_next_entry(item)
                zio.print IO.read(item)
              end
            end
          end
        end

        GoodData.upload_to_user_webdav(temp.path)
        process_id = options[:process]
        
        data = {
          :process => {
            :name => deploy_name,
            :path => "/uploads/#{File.basename(temp.path)}",
            :type => type
          }
        }
        res = if process_id.nil?
          GoodData.post("/gdc/projects/#{GoodData.project.pid}/dataload/processes", data)
        else
          GoodData.put("/gdc/projects/#{GoodData.project.pid}/dataload/processes/#{process_id}", data)
        end
      end
      puts HighLine::color("Deploy DONE #{dir}", HighLine::GREEN) if verbose
      res
    end


  end
end
