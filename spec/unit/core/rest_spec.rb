# encoding: UTF-8

require 'gooddata/core/connection'
require 'gooddata/core/rest'

describe GoodData do
  before(:each) do
    ConnectionHelper.create_default_connection
    GoodData.project = ProjectHelper.get_default_project
  end

  after(:each) do
    ConnectionHelper.disconnect
  end

  describe '#get_project_webdav_path' do
    it 'Returns path' do
      GoodData.get_project_webdav_path('test-file.csv')
    end
  end

  describe '#upload_to_project_webdav' do
    it 'Uploads file' do
      pending('Research how to properly upload file')
      GoodData.upload_to_project_webdav('spec/data/test-ci-data.csv')
    end
  end

  describe '#get_user_webdav_path' do
    it 'Gets the path' do
      GoodData.get_user_webdav_path('test.csv')
    end
  end
end