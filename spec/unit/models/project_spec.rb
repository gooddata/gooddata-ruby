# encoding: UTF-8

require 'gooddata'

describe GoodData::Project do
  before(:each) do
    ConnectionHelper::create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#all' do
    it 'Returns all projects' do
      expect { GoodData::Project.all }.to raise_error(RestClient::Forbidden)
    end
  end
end