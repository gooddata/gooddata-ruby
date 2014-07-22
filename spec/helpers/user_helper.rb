# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'project_helper'

module UserHelper

  class << self
    def remove_users
      users = GoodData::Domain.users_map(ConnectionHelper::DEFAULT_DOMAIN)
      users.each do |user|
        user.delete if user.email != ConnectionHelper::DEFAULT_USERNAME
      end
    end
  end
end