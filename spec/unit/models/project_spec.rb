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
      # TODO: This should not throw error
      expect { GoodData::Project.all }.to raise_error(RestClient::Forbidden)
    end
  end

  describe '#[]' do
    it 'Accepts :all parameter' do
      # TODO: This should not throw error
      expect { GoodData::Project[:all] }.to raise_error(RestClient::Forbidden)
    end
  end

  describe '#get_roles' do
    it 'Returns array' do
      proj = GoodData::Project['la84vcyhrq8jwbu4wpipw66q2sqeb923']
      roles = proj.get_roles
      expect(roles).to be_instance_of(Array)
    end
  end
end