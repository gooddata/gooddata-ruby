# encoding: UTF-8

require_relative '../exceptions/command_failed'
require_relative '../models/domain'

module GoodData
  module Command
    # Low level access to GoodData API
    class Domain
      attr_reader :name

      class << self
        def add_user(domain, login, password)
          GoodData::Domain.add_user(domain, login, password)
        end

        def list_users(domain)
          GoodData::Domain.users(domain)
        end
      end
    end
  end
end
