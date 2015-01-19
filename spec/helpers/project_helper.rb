# encoding: UTF-8

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

module ProjectHelper
  PROJECT_ID = 'we1vvh4il93r0927r809i3agif50d7iz'
  PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"
  PROJECT_TITLE = 'GoodTravis'
  PROJECT_SUMMARY = 'No summary'

  def self.get_default_project(opts = { :client => GoodData.connection })
    GoodData::Project[PROJECT_ID, opts]
  end

  def self.delete_old_projects(opts = {:client => GoodData.connection})
    projects = opts[:client].projects
    projects.each do |project|
      next if project.json['project']['meta']['author'] != client.user.uri
      next if project.pid == 'we1vvh4il93r0927r809i3agif50d7iz'
      begin
        puts "Deleting project #{project.title}"
        project.delete
      rescue e
        puts 'ERROR: ' + e.to_s
      end
    end
  end
end
