# encoding: UTF-8

require_relative '../models/profile'

module GoodData
  class << self
    # Gets currently logged user
    #
    # @return [GoodData::Profile] User Profile
    def user
      GoodData::Profile.current
    end

    alias_method :profile, :user
  end
end
