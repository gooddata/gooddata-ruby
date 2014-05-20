# encoding: utf-8

require_relative '../../lib/gooddata'

module GoodData
  module Apps
    class PocApp < GoodData::App
      DEFAULT_USERNAME = 'svarovsky+gem_tester@gooddata.com'
      DEFAULT_PASSWORD = 'jindrisska'

      def main(argv = ARGV)
        # Connect using username and password
        client = GoodData::Rest::Client.connect(DEFAULT_USERNAME, DEFAULT_PASSWORD)
        # pp client

        projects = client.find(GoodData::Project)
        pp projects

        project = projects[3]
        pp project

        # List invitations
        invitations = project.invitations
        invitations.each do |invitation|
          pp [invitation.author.email, invitation.email, invitation.project.title].join(', ')
        end


        # List projects
        # projects = client.all(GoodData::Project)
        # pp projects

        # Find all projects
        # projects = client.find(GoodData::Project)
        # pp projects

        # Find all projects by ID
        # projects = client.find(GoodData::Project, {:id => '123'})
        # pp projects

        # Find all projects by title
        # projects = client.find(GoodData::Project, {:title => 'GoodSales'})
        # pp projects
      end
    end
  end
end

# Run this ruby file as standalone ruby script if not included programmaticaly
if __FILE__ == $0
  app = GoodData::Apps::PocApp.new
  app.main
end
