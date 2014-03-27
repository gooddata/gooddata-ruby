# encoding: UTF-8

require 'gooddata/core/project'
require 'gooddata/models/project'

describe GoodData do
  PROJECT_ID = 'la84vcyhrq8jwbu4wpipw66q2sqeb923'
  PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"

  describe '#project=' do
    it 'Assigns nil' do
      GoodData.project = nil
    end

    it 'Assigns project using project ID' do
      GoodData.project = PROJECT_ID
    end

    it 'Assigns project using project URL' do
      GoodData.project = PROJECT_URL
    end

    it 'Assigns project directly' do
      GoodData.project = GoodData::Project[PROJECT_ID]
    end
  end

  describe '#project' do
    it 'Returns project assigned' do
      GoodData.project = nil
      GoodData.project.should == nil

      GoodData.project = PROJECT_ID
      GoodData.project.should_not == nil
    end
  end

  describe '#with_project' do
    it 'Uses project specified' do
      GoodData.with_project GoodData::Project[PROJECT_ID] do
      end
    end
  end
end