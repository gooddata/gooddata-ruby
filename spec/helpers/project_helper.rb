# encoding: UTF-8

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

module ProjectHelper
  PROJECT_ID = 'we1vvh4il93r0927r809i3agif50d7iz'
  PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"

  def self.get_default_project
    GoodData::Project[PROJECT_ID]
  end
end
