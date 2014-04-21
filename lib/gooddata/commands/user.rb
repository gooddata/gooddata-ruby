# encoding: UTF-8

require 'highline/import'
require 'multi_json'

require_relative '../cli/terminal'
require_relative '../helpers'

module GoodData::Command
  class User
    class << self
      def invite(project_id, email, role, msg = 'Join us!')
        puts "Inviting #{email}, role: #{role}"

        data = {
          :invitations => [{
            :invitation => {
              :content => {
                :email => email,
                :role => role,
                :action => {
                  :setMessage => msg
                }
              }
            }
         }]
        }

        url = "/gdc/projects/#{project_id}/invitations"
        GoodData.post(url, data)
      end
    end
  end
end
