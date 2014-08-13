# encoding: UTF-8

require_relative '../exceptions/command_failed'
require_relative '../models/domain'

module GoodData
  module Command
    # Low level access to GoodData API
    class Domain
      attr_reader :name

      class << self
        def add_user(domain, login, password, opts = { :client => GoodData.connection })
          data = {
            :domain => domain,
            :login => login,
            :password => password
          }
          GoodData::Domain.add_user(data.merge(opts))
        end

        def list_users(domain, opts = { :client => GoodData.connection })
          GoodData::Domain.users(domain, opts)
        end
      end
    end
  end
end
