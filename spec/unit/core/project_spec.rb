# encoding: UTF-8

require 'gooddata/connection'
require 'gooddata/core/connection'
require 'gooddata/core/project'
require 'gooddata/models/project'

describe 'GoodData.project' do
  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#project=' do
    it 'Assigns nil' do
      GoodData.project = nil
    end

    it 'Assigns project using project ID' do
      GoodData.project = ProjectHelper::PROJECT_ID
    end

    it 'Assigns project using project URL' do
      GoodData.project = ProjectHelper::PROJECT_URL
    end

    it 'Assigns project directly' do
      GoodData.project = ProjectHelper.default_project
    end
  end

  describe '#project' do
    it 'Returns project assigned' do
      GoodData.project = nil
      GoodData.project.should == nil

      GoodData.project = ProjectHelper::PROJECT_ID
      GoodData.project.should_not == nil
    end
  end

  describe '#with_project' do
    it 'Uses project specified' do
      GoodData.with_project ProjectHelper.default_project do
      end
    end
  end
end