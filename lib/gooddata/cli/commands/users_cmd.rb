# encoding: UTF-8

require 'pp'

require_relative '../shared'
require_relative '../../commands/user'

GoodData::CLI.module_eval do
  desc 'Basic User Management'
  arg_name 'list'
  command :user do |c|
    c.desc 'List users'
    c.command :list do |list|
      list.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)

        pid = args.first
        fail 'Project ID has to be provided' if pid.nil? || pid.empty?

        user_list = GoodData::Command::User.list(pid)
        puts user_list.map { |u| [u[:last_name], u[:first_name], u[:login], u[:uri]].join(',') }
      end
    end
  end
end
