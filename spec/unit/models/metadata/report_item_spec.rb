# encoding: UTF-8

require 'gooddata'

describe GoodData::ReportItem, :report => true do
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
      pending 'Create dashboard first'

      res = @item.report
      expect(res).to be_an_instance_of(GoodData::Report)
    end
  end
end