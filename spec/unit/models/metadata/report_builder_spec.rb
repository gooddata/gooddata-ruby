# encoding: UTF-8

require 'gooddata'

describe GoodData::ReportBuilder, :report => true do
  before(:each) do
    ConnectionHelper::create_default_connection
    @definition = ReportDefinitionHelper.default_definition
  end

  after(:each) do
    GoodData.disconnect
  end
end