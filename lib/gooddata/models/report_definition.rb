module GoodData
  class ReportDefinition < GoodData::MdObject 

    root_key :reportDefinition

    class << self
      def [](id)
        if id == :all
          GoodData.get(GoodData.project.md['query'] + '/reportdefinition/')['query']['entries']
        else 
          super
        end
      end

      def create_metrics_part(left, top)
        stuff = Array(left) + Array(top)
        stuff.find_all {|item| item.respond_to?(:is_metric?)}.map do |metric|
          create_metric_part(metric)
        end
      end

      def create_metric_part(metric)
        {
          "alias" => metric.title,
          "uri" => metric.uri
        }
      end

      def create_attribute_part(attrib)
        {
           "attribute" => {
              "alias" => "",
              "totals" => [],
              "uri" => attrib.uri
           }
        }
      end

      def create_part(stuff)
        stuff = Array(stuff)
        parts = stuff.reduce([]) do |memo, item|
          if item.respond_to?(:is_metric?)
            memo
          else
            memo << create_attribute_part(item)
          end
          memo
        end
        if stuff.any? {|item| item.respond_to?(:is_metric?)}
          parts << "metricGroup"
        end
        parts
      end

      def find(stuff)
        stuff.map do |item|
          if item.respond_to?(:is_attribute?)
            item.display_forms.first
          elsif item.is_a?(String)
            GoodData::Attribute.find_first_by_title(item).display_forms.first
          elsif item.is_a?(Hash) && item[:type].to_s == "metric"
            GoodData::Metric.find_first_by_title(item[:title])
          elsif item.is_a?(Hash) && item[:type].to_s == "attribute"
            GoodData::Attribute.find_first_by_title(item[:title]).display_forms.first
          else
            item
          end
        end
      end

      def execute(options={})
        left = Array(options[:left])
        top = Array(options[:top])

        metrics = (left + top).find_all {|item| item.respond_to?(:is_metric?)}

        unsaved_metrics = metrics.reject {|i| i.saved?}
        unsaved_metrics.each {|m| m.title = "Untitled metric" unless m.title}

        begin
          unsaved_metrics.each {|m| m.save}
          rd = GoodData::ReportDefinition.create(options)
          rd.save
          rd.execute
        ensure
          rd.delete if rd.saved? rescue nil
          unsaved_metrics.each {|m| m.delete if m.saved?}
        end
      end

      def create(options={})
        left = Array(options[:left])
        top = Array(options[:top])

        left = ReportDefinition.find(left)
        top = ReportDefinition.find(top)

        ReportDefinition.new({
           "reportDefinition" => {
              "content" => {
                 "grid" => {
                    "sort" => {
                      "columns" => [],
                      "rows" => []
                      },
                    "columnWidths" => [],
                    "columns" => ReportDefinition.create_part(top),
                    "metrics" => ReportDefinition.create_metrics_part(left, top),
                    "rows" => ReportDefinition.create_part(left),
                 },
                 "format" => "grid",
                 "filters" => []
              },
              "meta" => {
                 "tags" => "",
                 "summary" => "",
                 "title" => "Untitled report definition"
              }
           }
        })
      end
    end

    def metrics 
      content["grid"]["metrics"].map {|i| GoodData::Metric[i["uri"]]}
    end

    def execute
      result = GoodData.post '/gdc/xtab2/executor3', {"report_req" => {"reportDefinition" => uri}}
      data_result_uri = result["execResult"]["dataResult"]
      result = GoodData.get data_result_uri
      while result["taskState"] && result["taskState"]["status"] == "WAIT" do
         sleep 10
         result = GoodData.get data_result_uri
       end
      ReportDataResult.new(GoodData.get data_result_uri)
    end
  end    
end