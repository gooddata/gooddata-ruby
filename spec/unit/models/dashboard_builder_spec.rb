# encoding: UTF-8

require 'gooddata'

describe GoodData::Model::DashboardBuilder do
  DASHBOARD_TITLE = 'Test Dashboard'
  TAB_TITLE = 'Test Title'

  before(:each) do
    ConnectionHelper::create_default_connection
    @project = ProjectHelper.get_default_project
  end

  after(:each) do
    GoodData.disconnect
  end

  # Creates new dashboard
  def dashboard_create(title = DASHBOARD_TITLE)
    GoodData::Model::DashboardBuilder.new(title)
  end

  def dashboard_add_tab(dashboard)
    dashboard.add_tab TAB_TITLE do |tab|
    end
  end

  describe '#add_tab' do
    it 'Adds new tab and marks dirty' do
      db = dashboard_create
      dashboard_add_tab(db)

      db.dirty.should be_true
    end
  end

  describe '#create' do
    it 'Creates new dashboard' do
      options = {
        :title => DASHBOARD_TITLE,
        :tabs => [
          # First tab
          {
            :title => 'First tab'
          },

          # Second tab
          {
            :title => 'Second tab'
          }
        ]
      }

      GoodData::Model::DashboardBuilder.create(DASHBOARD_TITLE, options) do |dashboard|
        dashboard.save(@project)
        @dashboard = dashboard
      end
     @dashboard.delete
    end
  end

  describe '#initialize' do
    it 'Works' do
      db = dashboard_create
      db.should_not be_nil
    end
  end

  describe '#save!' do
    it 'Saves object if dirty' do
      db = dashboard_create
      dashboard_add_tab(db)

      db.dirty.should be_true

      db.save!
      db.dirty.should be_false
    end
  end
end
