# encoding: UTF-8

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

module ProjectHelper
  PROJECT_ID = 'we1vvh4il93r0927r809i3agif50d7iz'
  PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"

  class << self
    def default_project
      GoodData::Project[PROJECT_ID]
    end

    def remove_projects
      projects = GoodData::Project[:all]

      user = GoodData.user
      while !projects.empty?
        project = projects.shift
        should_delete =  project.author == user.uri && project.obj_id != PROJECT_ID
        project.delete if should_delete
      end
    end
  end
end
