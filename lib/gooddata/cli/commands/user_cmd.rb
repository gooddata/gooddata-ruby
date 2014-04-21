# encoding: UTF-8

require_relative '../shared'
require_relative '../../commands/user'

GoodData::CLI.module_eval do

  desc 'User management'
  command :user do |c|

    c.desc 'Invites user to project'
    c.command :invite do |store|
      store.action do |global_options, options, args|
        project_id = global_options[:project_id]
        fail 'Project ID has to be provided' if project_id.nil? || project_id.empty?

        email = args.first
        fail 'Email of user to be invited has to be provided' if email.nil? || email.empty?

        role = args[1]
        fail 'Role name has to be provided' if role.nil? || role.empty?

        opts = options.merge(global_options)
        GoodData.connect(opts)

        GoodData::Command::User.invite(project_id, email, role)
      end
    end

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
  end

end