# encoding: UTF-8

require 'gooddata'

describe GoodData::ReportItem, :report => true do
  before(:all) do
    ConnectionHelper::create_default_connection
    ReportHelper.create_default_reports
    DashboardHelper.create_default_dashboard
    GoodData.disconnect
  end

  after(:all) do
    ConnectionHelper::create_default_connection
    DashboardHelper.remove_default_dashboard
    ReportHelper.remove_default_reports
    GoodData.disconnect
  end

  before(:each) do
    ConnectionHelper::create_default_connection
    @dashboard = DashboardHelper.default_dashboard
    @tab = @dashboard.tabs.first
    @item = @tab.items.first
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#report' do

    it 'Returns report as GoodData::Report' do
      pending "Create items first!"

      res = @item.report
      expect(res).to be_an_instance_of(GoodData::Report)
    end
  end
end