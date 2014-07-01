# encoding: UTF-8

require 'gooddata'

describe GoodData::Dashboard::Tab do

  before(:each) do
    ConnectionHelper::create_default_connection
    @dashboard = DashboardHelper.default_dashboard
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#dashboard' do
    it 'Returns the dashboard which tab belongs to' do
      tab = @dashboard.tabs.first
      expect(tab.dashboard).to equal(@dashboard)
    end
  end
end