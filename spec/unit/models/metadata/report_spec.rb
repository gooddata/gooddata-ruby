# encoding: UTF-8

require 'gooddata'

describe GoodData::Report, :report => true do
  before(:each) do
    ConnectionHelper::create_default_connection
    @report = ReportHelper.default_report
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#author' do
    it 'Returns author as GoodData::Profile' do
      res = @report.author
      expect(res).to be_instance_of(GoodData::Profile)
    end
  end

  describe '#contributor' do
    it 'Returns contributor as GoodData::Profile' do
      res = @report.contributor
      expect(res).to be_instance_of(GoodData::Profile)
    end
  end

  describe '#definition' do
    it 'Returns report definition as GoodData::ReportDefinition' do
      res = @report.definition
      expect(res).to be_an_instance_of(GoodData::ReportDefinition)
    end
  end

  describe '#definitions' do
    it 'Returns report definitions as array of GoodData::ReportDefinition' do
      res = @report.definitions
      expect(res).to be_an_instance_of(Array)

      res.each do |definition|
        expect(definition).to be_an_instance_of(GoodData::ReportDefinition)
      end
    end
  end

  describe '#definitions_uris' do
    it 'Returns list of report definition URIs as Array of Strings' do
      res = @report.definitions_uris
      expect(res).to be_an_instance_of(Array)

      res.each do |definition|
        expect(definition).to be_an_instance_of(String)
      end
    end
  end

  describe '#latest_report_definition' do
    it 'Returns latest definition as GoodData::ReportDefinition' do
      res = @report.latest_report_definition
      expect(res).to be_an_instance_of(GoodData::ReportDefinition)
    end
  end

  describe '#latest_report_definition_uri' do
    it 'Returns latest definition URI as string' do
      res = @report.latest_report_definition_uri
      expect(res).to be_an_instance_of(String)
    end
  end

  describe '#remove_definition_but_latest' do
    it 'Removes all definitions except the latest one' do
      latest_definition_uri = @report.latest_report_definition_uri
      @report.remove_definition_but_latest
      expect(@report.definitions_uris.length).to be(1)
      expect(@report.latest_report_definition_uri).to be(latest_definition_uri)
    end
  end

  describe '#title' do
    it 'Returns title as String' do
      res = @report.title
      expect(res).to be_instance_of(String)
    end
  end
end