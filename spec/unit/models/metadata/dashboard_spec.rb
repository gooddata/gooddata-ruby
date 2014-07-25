# encoding: UTF-8

require 'gooddata'

describe GoodData::Dashboard, :dashboard => true do
  pending ("Broken bone ...")

  before(:all) do
    ConnectionHelper::create_default_connection
    @dashboard = DashboardHelper.create_default_dashboard
    GoodData.disconnect
  end

  after(:all) do
    ConnectionHelper::create_default_connection
    DashboardHelper.remove_default_dashboard
    GoodData.disconnect
  end

  before(:each) do
    ConnectionHelper::create_default_connection
    @dashboard = DashboardHelper.default_dashboard
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#author' do
    it 'Returns author as GoodData::Profile' do
      res = @dashboard.author
      expect(res).to be_instance_of(GoodData::Profile)
    end
  end

  describe '#contributor' do
    it 'Returns contributor as GoodData::Profile' do
      res = @dashboard.contributor
      expect(res).to be_instance_of(GoodData::Profile)
    end
  end

  describe '#created' do
    it 'Returns date when created as Time' do
      res = @dashboard.created
      expect(res).to be_instance_of(Time)
    end
  end

  describe '#tab' do
    it 'Returns tab by name as GoodData::Dashboard::Tab' do
      tab = {
        :title => DashboardHelper::DEFAULT_DASHBOARD_TAB_NAME,
        :items => [
        ]
      }

      @dashboard.add_tab(tab)
      res = @dashboard.save

      tab = @dashboard.tab(DashboardHelper::DEFAULT_DASHBOARD_TAB_NAME)
      expect(tab).to be_an_instance_of(GoodData::Dashboard::Tab)
      expect(tab.dashboard).to equal(@dashboard)
    end
  end

  describe '#tabs' do
    it 'Returns tabs as array of GoodData::Dashboard::Tab' do
      tabs = @dashboard.tabs
      expect(tabs).to be_an_instance_of(Array)
      tabs.each do |tab|
        expect(tab).to be_an_instance_of(GoodData::Dashboard::Tab)
        expect(tab.dashboard).to equal(@dashboard)
      end
    end
  end

  describe '#title' do
    it 'Returns title as String' do
      res = @dashboard.title
      expect(res).to be_instance_of(String)
    end
  end

  describe '#updated' do
    it 'Returns date when updated as Time' do
      res = @dashboard.updated
      expect(res).to be_instance_of(Time)
    end
  end
end