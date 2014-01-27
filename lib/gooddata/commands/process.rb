module GoodData::Command
  class Process

    def self.list(options={})
      # with project usage
      processes = GoodData::Process[:all]
    end

    def self.get(options={})
      id = options[:process_id]
      fail "Unspecified process id" if id.nil?
      GoodData::Process[id]
    end

    def self.with_deploy(dir, options={}, &block) 
      verbose = options[:verbose] || false
      if block
        begin
          res = deploy_graph(dir, options)
          block.call(res)
        ensure
          # self_link = res["process"]["links"]["self"]
          # GoodData.delete(self_link)
        end
      else
        deploy_graph(dir, options)
      end
    end

    def self.deploy_graph(dir, options={}) 
      dir = Pathname(dir) || fail("Directory is not specified")
      fail "\"#{dir}\" is not a directory" unless dir.directory?
      project_id = options[:project_id] || fail("Project Id has to be specified")
      

      type = options[:type] || fail("Type of deployment is not specified")
      deploy_name = options[:name]
      verbose = options[:verbose] || false
      project_pid = options[:project_pid]
      puts HighLine::color("Deploying #{dir}", HighLine::BOLD) if verbose
      res = nil

      Tempfile.open("deploy-graph-archive") do |temp|
        
        Zip::OutputStream.open(temp.path) do |zio|
          Dir.glob(dir + "**/*") do |item|
            puts "including #{item}" if verbose
            unless File.directory?(item)
              zio.put_next_entry(item)
              zio.print IO.read(item)
            end
          end
        end

        GoodData.connection.upload(temp.path)
        process_id = options[:process]
        
        data = {
          :process => {
            :name => deploy_name,
            :path => "/uploads/#{File.basename(temp.path)}",
            :type => type
          }
        }
        res = if process_id.nil?
          GoodData.post("/gdc/projects/#{project_pid}/dataload/processes", data)
        else
          GoodData.put("/gdc/projects/#{project_pid}/dataload/processes/#{process_id}", data)
        end
      end
      puts HighLine::color("Deploy DONE #{dir}", HighLine::BOLD) if verbose
      res
    end

    def self.execute_process(link, dir, options={})
      dir = Pathname(dir)
      type = :ruby
      if type == :ruby 
        result = GoodData.post(link, {
          :execution => {
           :graph => (dir + "main.rb").to_s,
           :params => options[:params]
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
        # if email.nil?
        #   result = execute_process(deploy_response["process"]["links"]["executions"], dir, options)
        # else
          # create_email_channel(options) do |channel_response|
            # subscribe_on_finish(:success, channel_response, deploy_response, options)
            result = execute_process(deploy_response["process"]["links"]["executions"], dir, options)
          # end
        # end
      end
    end

  end
end
