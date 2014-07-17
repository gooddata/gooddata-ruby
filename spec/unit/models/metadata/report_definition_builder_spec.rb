# encoding: UTF-8

require 'gooddata'

describe GoodData::ReportDefinitionBuilder, :report => true do
  before(:each) do
    ConnectionHelper::create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#create' do
    before do
      @definitions = []
    end

    after do
      until @definitions.empty?
        definition = @definitions.shift
        definition.delete
      end
    end

    it 'Builds GoodData::Report definition' do
      project = ProjectHelper.get_default_project
      metric = MetricHelper.default_metric

      GoodData::ReportDefinitionBuilder.chart_types.each do |chart_type|
        title = "Report #{metric.title} - #{chart_type}"
        definition = GoodData::ReportDefinitionBuilder.create(metric, :title => title, :type => chart_type)
        definition.save(project)

        @definitions << definition
      end
    end
  end
end