# encoding: UTF-8

module GoodData
  class << self
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