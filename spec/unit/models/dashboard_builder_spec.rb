# encoding: UTF-8

require 'gooddata'

describe GoodData::Model::DashboardBuilder do
  before(:each) do
    ConnectionHelper::create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#initialize' do
    it 'Works' do
      db = GoodData::Model::DashboardBuilder.new("test_title")
      db.should_not be_nil
    end
  end
end