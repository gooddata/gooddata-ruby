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

        # Show the connection result
        pp client

        # List projects
        # projects = client.all(GoodData::Project)
        #
        # Show projects listing result
        # pp projects

        # Find by resource class
        # find_result = client.find(GoodData::Project, 'id')

        # Find resource by arguments
        # find_result = client.find_by(GoodData::Project, {:title => 'GoodSales'})
      end
    end
  end
end

# Run this ruby file as standalone ruby script if not included programmaticaly
if __FILE__ == $0
  app = GoodData::Apps::PocApp.new
  app.main
end
