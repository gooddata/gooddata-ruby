# encoding: UTF-8

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

module ProjectHelper
  PROJECT_ID = 'hj7lx11gtcdh8z0q3zgpofz3qcnzkt7h'
  PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"

  def self.get_default_project
    GoodData::Project[PROJECT_ID]
  end
end
