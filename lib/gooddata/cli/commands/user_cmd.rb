# encoding: UTF-8

require_relative '../shared'
require_relative '../../commands/project'
require_relative '../../commands/role'
require_relative '../../commands/user'

GoodData::CLI.module_eval do

  desc 'User management'
  command :user do |c|
    c.desc 'List users'
    c.command :list do |list|
      list.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)

        pid = global_options[:project_id]
        fail 'Project ID has to be provided' if pid.nil? || pid.empty?

        user_list = GoodData::Command::User.list(pid)
        puts user_list.map { |u| [u[:last_name], u[:first_name], u[:login], u[:uri]].join(',') }
      end
    end

    c.desc 'Show your profile'
    c.command :show do |show|
      show.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        pp GoodData::Command::User.show()
      end
    end
  end

end