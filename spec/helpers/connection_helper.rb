require 'gooddata/connection'

module ConnectionHelper
  GD_PROJECT_TOKEN = ENV["GD_PROJECT_TOKEN"]
  DEFAULT_USERNAME = "svarovsky+gem_tester@goddata.com"
  DEFAULT_PASSWORD = "jindrisska"

  def self.create_default_connection(username = DEFAULT_USERNAME, password = DEFAULT_PASSWORD)
    GoodData::Connection.new(username, password)
  end

end