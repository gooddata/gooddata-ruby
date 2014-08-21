# encoding: UTF-8

require 'pp'

require_relative '../shared'
require_relative '../../commands/role'

GoodData::CLI.module_eval do
  desc 'Basic Role Management'
  arg_name 'list'
  command :role do |c|
    c.desc 'List roles'
    c.command :list do |list|
      list.action do |global_options, options, args|
        opts = options.merge(global_options)
        client = GoodData.connect(opts)

        pid = global_options[:project_id]
        fail 'Project ID has to be provided' if pid.nil? || pid.empty?

        role_list = GoodData::Command::Role.list(pid, :client => client)
        role_list.each do |k, v|
          puts [k, v[:uri]].join(',')
        end
      end
    end
  end
end
