# encoding: UTF-8

require_relative '../shared'
require_relative '../../commands/project'
require_relative '../../commands/role'
require_relative '../../commands/user'

GoodData::CLI.module_eval do
  desc 'User management'
  command :user do |c|
    c.desc 'Show your profile'
    c.command :show do |show|
      show.action do |global_options, options, _args|
        opts = options.merge(global_options)
        client = GoodData.connect(opts)
        pp GoodData::Command::User.show(client: client)
      end
    end
  end
end
