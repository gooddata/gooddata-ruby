# encoding: UTF-8

require_relative 'connection'
require_relative 'threaded'

require_relative '../models/account_settings'

module GoodData
  class << self
    # Attempts to log in
    def test_login
      connection.connect
    end

    # Returns the currently logged in user Profile.
    def profile
      threaded[:profile] ||= Profile.load
    end

    def user
      GoodData::AccountSettings.current
    end
  end
end
