# encoding: utf-8

require_relative '../../lib/gooddata'

module GoodData
  module Apps
    class PocApp < GoodData::App
      DEFAULT_USERNAME = 'svarovsky+gem_tester@gooddata.com'
      DEFAULT_PASSWORD = 'jindrisska'

      def main(argv = ARGV)
        client = GoodData::Rest::Client.connect(DEFAULT_USERNAME, DEFAULT_PASSWORD)

       #  projects = client.resource(GoodData::Project)
      end
    end
  end
end

if __FILE__ == $0
  app = GoodData::Apps::PocApp.new
  app.main
end
