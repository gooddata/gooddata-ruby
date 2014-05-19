# encoding: UTF-8

require_relative 'connection'
require_relative 'threaded'

require_relative '../models/profile'

module GoodData
  class << self
    # Attempts to log in
    def test_login
      connection.connect!
      connection.logged_in?
    end

    def user
      GoodData::Profile.current
    end

    alias_method :profile, :user
  end
end
