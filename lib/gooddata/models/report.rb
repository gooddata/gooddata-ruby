module GoodData
  class Report < GoodData::MdObject 

    class << self
      def [](id)
        if id == :all
          GoodData.get(GoodData.project.md['query'] + '/reports/')['query']['entries']
        else 
          super
        end
      end
    end

    def results
      content["results"]
    end

    def get_latest_report_definition_uri
      report_result = get_latest_report_result
      report_result.content["reportDefinition"]
    end

    def get_latest_report_definition
      GoodData::MdObject[get_latest_report_definition_uri]
    end

    def get_latest_report_result_uri
      results.last
    end

    def get_latest_report_result
      GoodData::MdObject[get_latest_report_result_uri]
    end

    def execute
      # puts "Executing report #{uri}"
      result = GoodData.post '/gdc/xtab2/executor3', {"report_req" => {"report" => uri}}
      dataResultUri = result["execResult"]["dataResult"]
      result = GoodData.get dataResultUri
      while result["taskState"] && result["taskState"]["status"] == "WAIT" do
         sleep 10
         result = GoodData.get dataResultUri
       end
       ReportDataResult.new(GoodData.get dataResultUri)
    end
  end
end
