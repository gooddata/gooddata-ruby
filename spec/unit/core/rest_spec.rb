# encoding: UTF-8

require 'gooddata/core/connection'
require 'gooddata/core/rest'

describe GoodData do
  before(:each) do
    @client = ConnectionHelper.create_default_connection
    @project = ProjectHelper.get_default_project(:client => @client)
  end

  after(:each) do
    @client.disconnect
  end

  describe '#get_project_webdav_path' do
    it 'Returns path' do
      @client.get_project_webdav_path('test-file.csv')
    end
  end

  describe '#upload_to_project_webdav' do
    it 'Uploads file' do
      pending('Research how to properly upload file')
      @client.upload_to_project_webdav('spec/data/test-ci-data.csv')
    end
  end

  describe '#get_user_webdav_path' do
    it 'Gets the path' do
      @client.get_user_webdav_path('test.csv')
    end
  end
end