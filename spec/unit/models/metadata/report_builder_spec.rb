# encoding: UTF-8

require 'gooddata'

describe GoodData::ReportBuilder, :report => true do
  before(:each) do
    ConnectionHelper::create_default_connection
    @definition = ReportDefinitionHelper.default_definition
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#create' do
    it 'Builds GoodData::Report' do
      project = ProjectHelper.get_default_project
      metric = MetricHelper.default_metric

      GoodData::ReportDefinitionBuilder.chart_types.each do |chart_type|
        title = "Report #{metric.title} - #{chart_type}"
        definition = GoodData::ReportDefinitionBuilder.create(metric, :title => title, :type => chart_type)
        definition.save(project)

        report = GoodData::ReportBuilder.create(definition)
        report.save(project)
      end
    end
  end
end