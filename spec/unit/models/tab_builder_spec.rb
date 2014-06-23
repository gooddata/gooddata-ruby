# encoding: UTF-8

require 'gooddata'

describe GoodData::Model::TabBuilder do
  TAB_TITLE = 'Test Tab Title'

  before(:each) do
    ConnectionHelper::create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#initialize' do
    it 'Works' do
      tb = GoodData::Model::TabBuilder.new(TAB_TITLE)
      tb.should_not be_nil
    end
  end
end