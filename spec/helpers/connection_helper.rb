require 'gooddata/connection'

module ConnectionHelper
  GD_PROJECT_TOKEN = ENV["GD_PROJECT_TOKEN"]

  DEFAULT_DOMAIN = ENV["GD_DOMAIN"] ?  ENV["GD_DOMAIN"] :'gooddata-tomas-svarovsky'
  DEFAULT_USERNAME = ENV["GD_USERNAME"] ?  ENV["GD_USERNAME"] : "svarovsky+gem_tester@gooddata.com"
  DEFAULT_PASSWORD = ENV["GD_PASSWORD"] ?  ENV["GD_PASSWORD"] :"jindrisska"
  DEFAULT_USER_URL = ENV["GD_USER_URL"] ?  ENV["GD_USER_URL"] :'/gdc/account/profile/3cea1102d5584813506352a2a2a00d95'
  DEFAULT_SERVER_URL = ENV["GD_SERVER_URL"] ? ENV["GD_SERVER_URL"] : "https://secure.gooddata.com"

  # Creates connection using default credentials or supplied one
  #
  # @param [String] username Optional username
  # @param [String] password Optional password
  def self.create_default_connection(username = DEFAULT_USERNAME, password = DEFAULT_PASSWORD, server = DEFAULT_SERVER_URL)
    GoodData::connect(username, password, {:server => server})

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

    GoodData::connect(username, password, {:server => DEFAULT_SERVER_URL})
  end
end
