# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'tempfile'

require 'gooddata/core/rest'

describe GoodData do
  before(:each) do
    @client = ConnectionHelper.create_default_connection
    # @project = ProjectHelper.get_default_project(:client => @client)
    @project = @client.create_project(title: 'Project for schedule testing', auth_token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
  end

  after(:each) do
    @project && @project.delete
    @client.disconnect
  end

  describe '#project_webdav_path' do
    it 'Returns path' do
      @client.project_webdav_path(:project => @project)
    end
  end

  def test_webdav_upload(params)
    GoodData.with_project(@project, :client => @client) do

      # use current timestamp as a directory name on webdav
      dir = params[:no_dir] ? nil : Time.now.to_i.to_s
      dir = "#{dir}/#{dir}" if params[:nested_dir]
      dir = "#{dir}/" if params[:slash_in_dir]

      # local file path
      path = 'spec/data/test-ci-data.csv'

      if params[:special_chars]
        source_file = Tempfile.new('abc-16:55:29+ha#he.csv')
        FileUtils.cp(path, source_file)
        path = source_file.path
      end

      path = File.expand_path(path) if params[:absolute_path]

      # upload it there
      upload_method = GoodData.method(params[:upload_method])
      upload_method.call(path, directory: dir)

      # download it from there
      temp_file = Tempfile.new('foo.csv')
      expect(temp_file.size).to be == 0

      download_method = GoodData.method(params[:download_method])

      file_basename = File.basename(path)
      file_basename = "NOTTHERE_#{file_basename}" if params[:unknown_file]

      download_block = proc do
        if params[:path_in_file]
          # pass the dir directly in the first param
          # e.g. GoodData.download_from_project_webdav('1234/test-ci-data.csv', '/tmp/myfile.csv')
          download_method.call(File.join(dir, file_basename).to_s, temp_file)
        else
          # pass the dir in the :directory option
          # e.g. GoodData.download_from_project_webdav('test-ci-data.csv', '/tmp/myfile.csv', :directory => '1234')
          download_method.call(file_basename, temp_file, directory: dir)
        end
      end

      # if it's unknown it should raise an error, otherwise it should download the right stuff
      if params[:unknown_file]
        expect{ download_block.call }.to raise_error(ArgumentError)
      else
        download_block.call

        expect(temp_file.size).to be > 0

        # expect the contents of the original file and the downloaded file are the same
        expect(IO.read(temp_file)).to be == IO.read(path)
      end
    end
  end

  describe '#download_from_project_webdav' do
    it "Works with directory directly in the 'file' param for project" do
      test_webdav_upload(
        upload_method: 'upload_to_project_webdav',
        download_method: 'download_from_project_webdav',
        path_in_file: true
      )
    end
    it "Works with directory directly in the 'file' param for user" do
      test_webdav_upload(
        upload_method: 'upload_to_user_webdav',
        download_method: 'download_from_user_webdav',
        path_in_file: true
      )
    end
    it "Works with directories with slash at the end for project" do
      test_webdav_upload(
        upload_method: 'upload_to_project_webdav',
        download_method: 'download_from_project_webdav',
        slash_in_dir: true
      )
    end
    it "Works with directories with slash at the end for user" do
      test_webdav_upload(
        upload_method: 'upload_to_user_webdav',
        download_method: 'download_from_user_webdav',
        slash_in_dir: true
      )
    end
    it "Fails for non-existing file for project" do
      test_webdav_upload(
        upload_method: 'upload_to_project_webdav',
        download_method: 'download_from_project_webdav',
        unknown_file: true
      )
    end
    it "Fails for non-existing file for user" do
      test_webdav_upload(
        upload_method: 'upload_to_user_webdav',
        download_method: 'download_from_user_webdav',
        unknown_file: true
      )
    end
    it 'Works with nested directories for project' do
      test_webdav_upload(
        upload_method: 'upload_to_project_webdav',
        download_method: 'download_from_project_webdav',
        nested_dir: true
      )
    end
    it 'Works with nested directories for user' do
      test_webdav_upload(
        upload_method: 'upload_to_user_webdav',
        download_method: 'download_from_user_webdav',
        nested_dir: true
      )
    end
    it 'Works with no directory for user' do
      test_webdav_upload(
        upload_method: 'upload_to_user_webdav',
        download_method: 'download_from_user_webdav',
        no_dir: true
      )
    end
    it 'Works with no directory for project' do
      test_webdav_upload(
        upload_method: 'upload_to_project_webdav',
        download_method: 'download_from_project_webdav',
        no_dir: true
      )
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

    it 'Uploads file with special chars in filename' do
      test_webdav_upload(
        special_chars: true,
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
    it 'Uploads file with special chars in filename' do
      test_webdav_upload(
        special_chars: true,
        upload_method: 'upload_to_user_webdav',
        download_method: 'download_from_user_webdav'
      )
    end
  end

  describe '#user_webdav_path' do
    it 'Gets the path' do
      expect(@client.user_webdav_path).to eq GoodData::Environment::ConnectionHelper::STAGING_URI
    end
  end
end