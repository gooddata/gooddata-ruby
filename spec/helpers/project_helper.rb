# encoding: UTF-8

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

module ProjectHelper
  PROJECT_ID = 'ghbpozicaidf1b9s0ohsa6msu7792c1k'
  PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"

  def self.get_default_project
    GoodData::Project[PROJECT_ID]
  end
end
