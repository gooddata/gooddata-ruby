# encoding: UTF-8

require 'gooddata/core/connection'
require 'gooddata/core/rest'

describe GoodData do
  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    GoodData.disconnect
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
end