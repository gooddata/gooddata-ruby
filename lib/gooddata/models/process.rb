require 'pry'
require 'highline'

module GoodData
  class Process

    class << self
      def [](id)
        if id == :all
          GoodData.get("/gdc/projects/#{GoodData.project.pid}/dataload/processes")
        else 
          self.new(GoodData.get("/gdc/projects/#{GoodData.project.pid}/dataload/processes/#{id}"))
        end
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
