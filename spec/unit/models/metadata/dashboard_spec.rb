# encoding: UTF-8

require 'gooddata'

describe GoodData::Dashboard do
  before(:each) do
    ConnectionHelper::create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  def get_default_dashboard
    project = ProjectHelper.get_default_project
    project.dashboards.first
  end

  describe '#author' do
    it 'Returns author as GoodData::Profile' do
      dashboard = get_default_dashboard

      res = dashboard.author
      expect(res).to be_instance_of(GoodData::Profile)
    end
  end

  describe '#contributor' do
    it 'Returns contributor as GoodData::Profile' do
      dashboard = get_default_dashboard

      res = dashboard.contributor
      expect(res).to be_instance_of(GoodData::Profile)
    end
  end

  describe '#title' do
    it 'Returns title as String' do
      dashboard = get_default_dashboard

      res = dashboard.title
      expect(res).to be_instance_of(String)
    end
  end
end