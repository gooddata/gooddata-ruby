# encoding: UTF-8

require_relative 'connection'
require_relative 'threaded'

module GoodData
  class << self
    # Attempts to log in
    def test_login
      connection.connect!
      connection.logged_in?
    end

    # Returns the currently logged in user Profile.
    def profile
      threaded[:profile] ||= Profile.load
    end
  end
end