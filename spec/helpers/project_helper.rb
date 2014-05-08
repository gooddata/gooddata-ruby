# encoding: UTF-8

# Global requires
require 'multi_json'

# Local requires
require_relative 'connection_helper'

require 'gooddata/models/models'

module ProjectHelper
  def self.load_project_name
    json_path = File.join(File.dirname(__FILE__), '..', 'data', 'test_project_model_spec.json')
    json = MultiJson.load(File.read(json_path, :symbolize_keys => true))
    json['title']
  end

  # Load from JSON
  TEST_PROJECT_NAME = load_project_name

  def self.create_test_project
    json_path = File.join(File.dirname(__FILE__), '..', 'data', 'test_project.json')
    json = MultiJson.load(File.read(json_path, :symbolize_keys => true))
    json['project']['content']['authorizationToken'] = ENV['GD_PROJECT_TOKEN']

    project = GoodData::Project.new(json)
    project.save

    GoodData.wait_for_polling_result(project.uri, { 'project' => { 'content' => { 'state' => 'ENABLED'}}})

    roles = project.roles

    # project.invite(ConnectionHelper::DEFAULT_USERNAME, )

    project
  end

  PROJECT_ID = nil
  PROJECT_URL = nil
end
