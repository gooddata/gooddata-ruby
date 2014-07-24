# encoding: UTF-8

require 'gooddata'

describe GoodData::ReportBuilder, :report => true do
  before(:each) do
    ConnectionHelper::create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#create' do
    before do
      @reports = []
    end

    after do
      until @reports.empty?
        report = @reports.shift
        report.delete
      end
    end
    it 'Builds GoodData::Report' do
      project = ProjectHelper.default_project
      metric = MetricHelper.default_metric

      GoodData::ReportDefinitionBuilder.chart_types.each do |chart_type|
        title = "Report #{metric.title} - #{chart_type}"
        definition = GoodData::ReportDefinitionBuilder.create(metric, :title => title, :type => chart_type)
        definition.save(project)

        report = GoodData::ReportBuilder.create(definition)
        report.save(project)

        @reports << report
      end
    end
  end
end