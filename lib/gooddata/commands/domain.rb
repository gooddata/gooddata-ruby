# encoding: UTF-8

require_relative '../exceptions/command_failed'

module GoodData
  module Command
    # Low level access to GoodData API
    class Domain
      class << self
        def add_user(domain, firstname, lastname, login, password)
          data = {
            :accountSetting => {
              :login => login,
              :password => password,
              :verifyPassword => password,
              :email => login,
              :firstName => firstname,
              :lastName => lastname
            }
          }

          url = "/gdc/account/domains/#{domain}/users"
          GoodData.post(url, data)
        end

        def list_users(domain)
          result = []

          tmp = GoodData.get("/gdc/account/domains/#{domain}/users")
          tmp['accountSettings']['items'].each do |account|
            result << account['accountSetting']
          end

          result
        end
      end
    end
  end
end
