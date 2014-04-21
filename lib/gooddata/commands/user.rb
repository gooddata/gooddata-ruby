# encoding: UTF-8

require_relative '../core/core'

require 'highline/import'
require 'multi_json'

module GoodData::Command
  class User
    class << self


      def get_roles(pid)
        roles_response = GoodData.get("/gdc/projects/#{pid}/roles")

        roles = {}
        roles_response["projectRoles"]["roles"].each do |role_uri|
          r = GoodData.get(role_uri)
          identifier = r["projectRole"]["meta"]["identifier"]
          roles[identifier] = {
            :user_uri => r["projectRole"]["links"]["roleUsers"],
            :uri => role_uri
          }
        end
        roles
      end

      def show
        GoodData.profile.to_json
      end
    end
  end
end