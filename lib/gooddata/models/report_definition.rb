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
            x = GoodData::MdObject.get_by_id(item)
            fail "Object given by id \"#{item}\" could not be found" if x.nil?
            case x.raw_data.keys.first.to_s
            when "attribute"
              GoodData::Attribute.new(x.raw_data).display_forms.first
            when "attributeDisplayForm"
              GoodData::DisplayForm.new(x.raw_data)
            when "metric"
              GoodData::Metric.new(x.raw_data)
            end
          elsif item.is_a?(Hash) && item.keys.include?(:title)
            case item[:type].to_s
            when "metric"
              GoodData::Metric.find_first_by_title(item[:title])
            when "attribute"
              GoodData::Attribute.find_first_by_title(item[:title]).display_forms.first
            end
          elsif item.is_a?(Hash) && (item.keys.include?(:id))
            case item[:type].to_s
            when "metric"
              GoodData::Metric.get_by_id(item[:id])
            when "attribute"
              GoodData::Attribute.get_by_id(item[:id]).display_forms.first
            when "label"
              GoodData::DisplayForm.get_by_id(item[:id])
            end
          elsif item.is_a?(Hash) && (item.keys.include?(:identifier))
            case item[:type].to_s
            when "metric"
              GoodData::Metric.get_by_id(item[:identifier])
            when "attribute"
              GoodData::Attribute.get_by_id(item[:identifier]).display_forms.first
            when "label"
              GoodData::DisplayForm.get_by_id(item[:identifier])
            end
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
          rd.delete if rd && rd.saved?
          unsaved_metrics.each {|m| m.delete if m &&  m.saved?}
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
      result = if saved?
        GoodData.post '/gdc/xtab2/executor3', {"report_req" => {"reportDefinition" => uri}}
      else
        # GoodData.post '/gdc/xtab2/executor3', {"report_req" => raw_data}
        fail("this is currently unsupported. For executing unsaved report definitions please use class method execute.")
      end
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