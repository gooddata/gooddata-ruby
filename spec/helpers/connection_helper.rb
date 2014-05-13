require 'gooddata/connection'

module ConnectionHelper
  GD_PROJECT_TOKEN = ENV["GD_PROJECT_TOKEN"]

  DEFAULT_USERNAME = "svarovsky+gem_tester@gooddata.com"
  DEFAULT_PASSWORD = "jindrisska"
  DEFAULT_DOMAIN = 'gooddata-tomas-svarovsky'

  # Creates connection using default credentials or supplied one
  #
  # @param [String] username Optional username
  # @param [String] password Optional password
  def self.create_default_connection(username = DEFAULT_USERNAME, password = DEFAULT_PASSWORD)
    GoodData::connect(username, password)
  end

  # Creates connection using environment varibles GD_GEM_USER and GD_GEM_PASSWORD
  def self.create_private_connection
    username = ENV['GD_GEM_USER'] || DEFAULT_USERNAME
    password = ENV['GD_GEM_PASSWORD'] || DEFAULT_PASSWORD

    GoodData::connect(username, password)
  end
end
