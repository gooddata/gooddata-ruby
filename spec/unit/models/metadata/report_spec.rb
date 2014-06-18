# encoding: UTF-8

require 'gooddata'

describe GoodData::Report do
  before(:each) do
    ConnectionHelper::create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  def get_default_report
    project = ProjectHelper.get_default_project
    project.reports.first
  end

  describe '#author' do
    it 'Returns author as GoodData::Profile' do
      report = get_default_report
      res = report.author
      expect(res).to be_instance_of(GoodData::Profile)
    end
  end

  describe '#contributor' do
    it 'Returns contributor as GoodData::Profile' do
      report = get_default_report

      res = report.contributor
      expect(res).to be_instance_of(GoodData::Profile)
    end
  end

  describe '#definition' do
    it 'Returns report definition as GoodData::MdObject' do
      report = get_default_report

      res = report.definition
      expect(res).to be_an_instance_of(GoodData::ReportDefinition)
    end
  end

  describe '#title' do
    it 'Returns title as String' do
      report = get_default_report

      res = report.title
      expect(res).to be_instance_of(String)
    end
  end
end