# encoding: UTF-8

require_relative '../shared'
require_relative '../../commands/domain'

GoodData::CLI.module_eval do

  desc 'Manage domain'
  command :domain do |c|

    c.desc 'Add user to domain'
    c.command :add_user do |add_user|
      add_user.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)

        domain = args[0]
        fail 'Domain name has to be provided' if domain.nil? || domain.empty?

        first = args[1]
        fail 'Firstname has to be provided' if first.nil? || first.empty?

        last = args[2]
        fail 'Lastname has to be provided' if last.nil? || last.empty?

        email = args[3]
        fail 'Email has to be provided' if email.nil? || email.empty?

        password = args[4]
        fail 'Password has to be provided' if password.nil? || password.empty?

        GoodData::Command::Domain.add_user(domain, first, last, email, password)
      end
    end

    c.desc 'List users in domain'
    c.command :list_users do |list_users|
      list_users.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)

        domain = args[0]
        fail 'Domain name has to be provided' if domain.nil? || domain.empty?


        users = GoodData::Command::Domain.list_users(domain)
        puts users.map { |u| [u['firstName'], u['lastName'], u['login']].join(',') }
      end
    end
  end

end