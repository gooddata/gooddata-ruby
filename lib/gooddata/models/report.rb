module GoodData
  class Report < GoodData::MdObject 

    root_key :report

    class << self
      def [](id)
        if id == :all
          GoodData.get(GoodData.project.md['query'] + '/reports/')['query']['entries']
        else 
          super
        end
      end
            
      def create(options={})
        title = options[:title]
        summary = options[:summary] || ""
        rd = options[:rd] || ReportDefinition.create(:top => options[:top], :left => options[:left])
        rd.save

        report = Report.new({
           "report" => {
              "content" => {
                 "domains" => [],
                 "definitions" => [rd.uri]
              },
              "meta" => {
                 "tags" => "",
                 "deprecated" => "0",
                 "summary" => summary,
                 "title" => title
              }
           }
        })        
      end
    end

# ----

    def title=(a_title)
      @json["report"]["meta"]["title"] = a_title
    end

    def summary=(a_summary)
      @json[:report][:meta][:summary] = a_summary
    end

    def add_definition(a_definition)
      @json[:report][:content][:definitions] << a_definition
    end
    
# ----



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
