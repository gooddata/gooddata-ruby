require 'pry'
require 'highline'

module GoodData
  class Process

    class << self
      def [](id)
        if id == :all
          GoodData.get("/gdc/projects/hi95siviyangv53c3vptkz1eas546pnn/dataload/processes")
        else 
          self.new(GoodData.get("/gdc/projects/hi95siviyangv53c3vptkz1eas546pnn/dataload/processes/#{id}"))
        end
      end

      def deploy(dir, options={}, &block) 
        if block
          begin
            res = deploy_graph(dir, options)
            block.call(res)
          ensure
            self_link = res["process"]["links"]["self"]
            GoodData.delete(self_link)
          end
        else
          deploy_graph(dir, options)
        end
      end

      def deploy_graph(dir, options={}) 
        dir = Pathname(dir)
        fail "Provided path (#{dir}) is not directory." unless dir.directory?
        type = options[:type] || "ETL"
        
        deploy_name = options[:name] || options[:project_name]
        verbose = options[:verbose] || false
        project_pid = 'hi95siviyangv53c3vptkz1eas546pnn'
        
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
    end

    def initialize(data)
      @data = data
    end

    def links
      @data["process"]["links"]
    end
    
    def link
      links["self"]
    end

    def executions_link
      links["executions"]
    end

    def execute_process(graph, options={})
      result = GoodData.post(executions_link, {
        :execution => {
         :graph => graph,
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
end
