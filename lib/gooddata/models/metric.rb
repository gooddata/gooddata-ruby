require 'gooddata/goodzilla/goodzilla'

module GoodData
  class Metric < GoodData::MdObject 

    root_key :metric

    class << self
      def [](id)
        if id == :all
          GoodData.get(GoodData.project.md['query'] + '/metrics/')['query']['entries']
        else 
          super
        end
      end

      def xcreate(options)
        if options.is_a?(String)
          create({:expression => options, :extended_notation => true})
        else
          create(options.merge({:extended_notation => true}))
        end
      end

      def create(options={})
        if options.is_a?(String)
          expression = options
          extended_notation = true
          title = nil
        else
          title = options[:title]
          summary = options[:summary]
          expression = options[:expression] || fail("Metric has to have its expression defined")
          extended_notation = options[:extended_notation]
        end

        expression = if extended_notation
          dict = {
            :facts => GoodData::Fact[:all].reduce({}) {|memo, item| memo[item["title"]] = item["link"]; memo},
            :attributes => GoodData::Attribute[:all].reduce({}) {|memo, item| memo[item["title"]] = item["link"]; memo},
            :metrics => GoodData::Metric[:all].reduce({}) {|memo, item| memo[item["title"]] = item["link"]; memo},
          }
          interpolated_metric = GoodData::SmallGoodZilla.interpolate_metric(expression, dict)
          interpolated_metric
        else
          expression
        end

        Metric.new({
           "metric" => {
              "content" => {
                 "format" => "#,##0",
                 "expression" => expression
              },
              "meta" => {
                 "tags" => "",
                 "summary" => summary,
                 "title" => title,
              }
           }
        })
      end

      def execute(expression, options={})
        m = GoodData::Metric.create({:title => "Temporary metric to be deleted", :expression => expression}.merge(options))
        m.execute
      end

      def xexecute(expression)
        execute(expression, {:extended_notation => true})
      end

    end

    def execute
      res = GoodData::ReportDefinition.execute(:left => self)
      res.to_table[0][0]
    end

    def validate
      fail "Meric needs to have title" if title.nil?
      true
    end

    def is_metric?
      true
    end
      
  end
end
