# encoding: UTF-8

require 'gooddata/connection'
require 'gooddata/core/connection'
require 'gooddata/core/project'
require 'gooddata/models/project'

describe 'GoodData - project' do
  before(:each) do
    @client = ConnectionHelper.create_default_connection
  end

  after(:each) do
    @client.disconnect
  end

  describe '#project=' do
    it 'Assigns nil' do
      GoodData.project = nil
    end

    it 'Assigns project using project ID' do
      pending 'GoodData::project= is disabled for now'
      GoodData.project = ProjectHelper::PROJECT_ID
    end

    it 'Assigns project using project URL' do
      pending 'GoodData::project= is disabled for now'
      GoodData.project = ProjectHelper::PROJECT_URL
    end

    it 'Assigns project directly' do
      pending 'GoodData::project= is disabled for now'
      GoodData.project = GoodData::Project[ProjectHelper::PROJECT_ID]
    end
  end

  describe '#project' do
    it 'Returns project assigned' do
      pending 'GoodData.project= is disabled for now'

      GoodData.project = nil
      GoodData.project.should == nil

      GoodData.project = ProjectHelper::PROJECT_ID
      GoodData.project.should_not == nil
    end
  end

  describe '#with_project' do
    it 'Uses project specified' do
      GoodData.with_project GoodData::Project[ProjectHelper::PROJECT_ID, :client => @client] do
      end
    end
  end
end