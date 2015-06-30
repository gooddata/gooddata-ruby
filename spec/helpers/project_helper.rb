# encoding: UTF-8

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

require_relative '../environment/environment'

GoodData::Environment.load

module GoodData::Helpers
  module ProjectHelper
    include GoodData::Environment::ProjectHelper

    ENVIRONMENT = 'TESTING'

    def self.get_default_project(opts = {:client => GoodData.connection})
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

    def self.create_random_user(client)
      num = rand(1e7)
      login = "gemtest#{num}@gooddata.com"

      opts = {
        email: login,
        login: login,
        first_name: 'the',
        last_name: num.to_s,
        role: 'editor',
        password: CryptoHelper.generate_password,
        domain: ConnectionHelper::DEFAULT_DOMAIN
      }
      GoodData::Membership.create(opts, client: client)
    end
  end

end
