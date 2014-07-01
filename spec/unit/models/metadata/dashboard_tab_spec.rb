# encoding: UTF-8

require 'gooddata'

describe GoodData::Dashboard::Tab do

  before(:each) do
    ConnectionHelper::create_default_connection
    @dashboard = DashboardHelper.default_dashboard
    @tab = @dashboard.tabs.first
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#dashboard' do
    it 'Returns the dashboard which tab belongs to' do
      res = @tab.dashboard
      expect(res).to equal(@dashboard)
    end
  end

  describe '#identifier' do
    it 'Returns dashboard identifier as String' do
      res = @tab.identifier
      expect(res).to be_an_instance_of(String)
      expect(res).to include(DashboardHelper::DEFAULT_DASHBOARD_TAB_IDENTIFIER)
    end
  end

  describe '#items' do
    it 'Returns items as Array of ReportItem' do
      res = @tab.items
      expect(res).to be_an_instance_of(Array)
      res.each do |r|
        expect(r).to be_an_instance_of(GoodData::ReportItem)
      end
    end
  end

  describe '#reports' do
    it 'Returns array of reports' do
      res = @tab.reports
      expect(res).to be_an_instance_of(Array)
      res.each do |r|
        expect(r).to be_an_instance_of(GoodData::Report)
      end
    end
  end

  describe '#title' do
    it 'Returns dashboard tab identifier as String' do
      res = @tab.title
      expect(res).to be_an_instance_of(String)
      expect(res).to include(DashboardHelper::DEFAULT_DASHBOARD_TAB_NAME)
    end
  end
end