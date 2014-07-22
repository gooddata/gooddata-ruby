# encoding: UTF-8

require 'gooddata'

describe GoodData::Model::DashboardBuilder do
  before(:each) do
    ConnectionHelper::create_default_connection
    @project = ProjectHelper.default_project
  end

  after(:each) do
    GoodData.disconnect
  end

  # Creates new dashboard
  def dashboard_create(title = DashboardHelper::DASHBOARD_TITLE)
    GoodData::Model::DashboardBuilder.new(title)
  end

  def dashboard_add_tab(dashboard)
    dashboard.add_tab DashboardHelper::TAB_TITLE do |tab|
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
        :title => "#{DashboardHelper::DASHBOARD_TITLE} #{Time.new.strftime('%Y%m%d%H%M%S')}",
        :tabs => [
          # First tab
          {
            :title => "First Tab #{Time.new.strftime('%Y%m%d%H%M%S')}",
            :items => [
              # First row
              [],

              # Second row
              []
            ]
          },

          # Second tab
          {
            :title => "Second Tab #{Time.new.strftime('%Y%m%d%H%M%S')}",
            :items => [
              # First row
              [],

              # Second row
              []
            ]
          }
        ]
      }

      GoodData::Model::DashboardBuilder.create(options) do |dashboard|
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
