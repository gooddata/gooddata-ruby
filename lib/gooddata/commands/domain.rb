# encoding: UTF-8

require_relative '../exceptions/command_failed'

module GoodData
  module Command
    # Low level access to GoodData API
    class Domain
      class << self
        def add_user(domain)
        end

        def list_users(domain)
          result = []

          tmp = GoodData.get("/gdc/account/domains/#{domain}/users")
          tmp['accountSettings']['items'].each do |account|
            result << account['accountSetting']
          end

          return result
        end
      end
    end
  end
end