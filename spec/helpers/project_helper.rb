# encoding: UTF-8

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

module ProjectHelper
  def self.load_project_name
    json_path = File.join(File.dirname(__FILE__), '..', 'data', 'test_project_model_spec.json')
    json = MultiJson.load(File.read(json_path, :symbolize_keys => true))
    json['title']
  end

  PROJECT_ID = nil
  PROJECT_URL = nil

  # Load from JSON
  TEST_PROJECT_NAME = load_project_name
end
