# encoding: UTF-8

require_relative '../core/core'

module GoodData
  module Command
    class Role
      class << self
        def list(pid)
          roles_response = GoodData.get("/gdc/projects/#{pid}/roles")

          roles = {}
          roles_response['projectRoles']['roles'].each do |role_uri|
            r = GoodData.get(role_uri)
            identifier = r['projectRole']['meta']['identifier']
            roles[identifier] = {
              :user_uri => r['projectRole']['links']['roleUsers'],
              :uri => role_uri
            }
          end
          roles
        end
      end
    end
  end
end
