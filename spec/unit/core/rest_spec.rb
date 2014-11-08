# encoding: UTF-8
require 'tempfile'

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
      @client.get_project_webdav_path('test-file.csv', :project => @project)
    end
  end


  def test_webdav_upload(params)
    GoodData.with_project(@project, :client => @client) do
      dir = Time.now.to_i.to_s

      path = 'spec/data/test-ci-data.csv'

      path = File.expand_path(path) if params[:absolute_path]

      # upload it there
      upload_method = GoodData.method(params[:upload_method])
      upload_method.call(path, directory: dir)

      # download it from there
      file = Tempfile.new('foo.csv')

      download_method = GoodData.method(params[:download_method])
      download_method.call('test-ci-data.csv', file, directory: dir)

      file.size.should be > 0
    end

  end
  describe '#upload_to_project_webdav' do
    it 'Uploads file with relative path to a dir' do
      test_webdav_upload(
        upload_method: 'upload_to_project_webdav',
        download_method: 'download_from_project_webdav'
      )
    end

    it 'Uploads file with absolute path to a dir' do
      test_webdav_upload(
        absolute_path: true,
        upload_method: 'upload_to_project_webdav',
        download_method: 'download_from_project_webdav'
      )
    end
  end

  describe '#upload_to_user_webdav' do
    it 'Uploads file with relative path to a dir' do
      test_webdav_upload(
        upload_method: 'upload_to_user_webdav',
        download_method: 'download_from_user_webdav'
      )
    end

    it 'Uploads file with absolute path to a dir' do
      test_webdav_upload(
        absolute_path: true,
        upload_method: 'upload_to_user_webdav',
        download_method: 'download_from_user_webdav'
      )
    end
  end


  describe '#get_user_webdav_path' do
    it 'Gets the path' do
      @client.get_user_webdav_path('test.csv', :project => @project)
    end
  end
end