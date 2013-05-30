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
      result = GoodData.post '/gdc/xtab2/executor3', {"report_req" => {"report" => uri}}
      data_result_uri = result["execResult"]["dataResult"]
      result = GoodData.get data_result_uri
      while result["taskState"] && result["taskState"]["status"] == "WAIT" do
         sleep 10
         result = GoodData.get data_result_uri
       end
      ReportDataResult.new(GoodData.get data_result_uri)
    end

    def export(format)
      result = GoodData.post('/gdc/xtab2/executor3', {"report_req" => {"report" => uri}})
      result1 = GoodData.post('/gdc/exporter/executor', {:result_req => {:format => format, :result => result}})
      png = GoodData.get(result1['uri'], :process => false)
      while (png.code == 202) do
        sleep(1)
        png = GoodData.get(result1['uri'], :process => false)
      end
      png
    end

  end
end
