# encoding: UTF-8

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

module ProjectHelper
  PROJECT_ID = 'y4k4shccnvkvpgeefp2l2vr92mc7g2j4'
  PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"

  def self.get_default_project
    GoodData::Project[PROJECT_ID]
  end
end
