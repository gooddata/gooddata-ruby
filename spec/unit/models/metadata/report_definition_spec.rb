# encoding: UTF-8

require 'gooddata'

describe GoodData::ReportDefinition, :report => true do
  before(:all) do
    ConnectionHelper.create_default_connection
    ReportHelper.create_default_reports
    GoodData.disconnect
  end

  after(:all) do
    ConnectionHelper.create_default_connection
    ReportHelper.delete_all_reports
    GoodData.disconnect
  end

  before(:each) do
    ConnectionHelper::create_default_connection
    @definition = ReportDefinitionHelper.default_definition
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#author' do
    it 'Returns author as GoodData::Profile' do
      res = @definition.author
      expect(res).to be_instance_of(GoodData::Profile)
    end
  end

  describe '#contributor' do
    it 'Returns contributor as GoodData::Profile' do
      res = @definition.contributor
      expect(res).to be_instance_of(GoodData::Profile)
    end
  end

  describe '#created' do
    it 'Returns created date as DateTime' do
      res = @definition.created
      expect(res).to be_an_instance_of(Time)
    end
  end

  describe '#title' do
    it 'Returns title as String' do
      res = @definition.title
      expect(res).to be_instance_of(String)
    end
  end

  describe '#updated' do
    it 'Returns updated date as DateTime' do
      res = @definition.updated
      expect(res).to be_an_instance_of(Time)
    end
  end
end