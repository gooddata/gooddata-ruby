require 'gooddata/connection'

module ConnectionHelper
  GD_PROJECT_TOKEN = ENV["GD_PROJECT_TOKEN"]

  DEFAULT_USERNAME = "svarovsky+gem_tester@gooddata.com"
  DEFAULT_PASSWORD = "jindrisska"
  DEFAULT_DOMAIN = 'gooddata-tomas-svarovsky'
  DEFAULT_USER_URL = '/gdc/account/profile/3cea1102d5584813506352a2a2a00d95'

  # Creates connection using default credentials or supplied one
  #
  # @param [String] username Optional username
  # @param [String] password Optional password
  def self.create_default_connection(username = DEFAULT_USERNAME, password = DEFAULT_PASSWORD)
    GoodData::connect(username, password)
  end

  def self.disconnect
    conn = GoodData.connection.connection
    GoodData.disconnect
    puts conn.stats_table
  end

  # Creates connection using environment varibles GD_GEM_USER and GD_GEM_PASSWORD
  def self.create_private_connection
    username = ENV['GD_GEM_USER'] || DEFAULT_USERNAME
    password = ENV['GD_GEM_PASSWORD'] || DEFAULT_PASSWORD

    GoodData::connect(username, password)
  end
end
