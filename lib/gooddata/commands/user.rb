# encoding: UTF-8

require_relative '../core/core'

module GoodData::Command
  class User
    class << self
      def list(pid)
        users = []
        finished = false
        offset = 0
        # Limit set to 1000 to be safe
        limit = 1000
        while (!finished) do
          result = GoodData.get("/gdc/projects/#{pid}/users?offset=#{offset}&limit=#{limit}")
          result["users"].map do |u|
            as = u['user']
            users.push(
              {
                :login => as['content']['email'],
                :uri => as['links']['self'],
                :first_name => as['content']['firstname'],
                :last_name => as['content']['lastname'],
                :role => as['content']['userRoles'].first,
                :status => as['content']['status']
              }
            )
          end
          if (result["users"].count == limit) then
            offset = offset + limit
          else
            finished = true
          end
        end
        users
      end
    end
  end
end