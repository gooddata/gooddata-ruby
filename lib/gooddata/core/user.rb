# encoding: UTF-8

require_relative 'connection'
require_relative 'threaded'

require_relative '../models/profile'

module GoodData
  class << self

    # Attempts to log in
    #
    # @return [Boolean] True if logged in else false
    def test_login
      connection.connect!
      connection.logged_in?
    end

    # Gets currently logged user
    #
    # @return [GoodData::Profile] User Profile
    def user
      GoodData::Profile.current
    end

    alias_method :profile, :user
  end
end
