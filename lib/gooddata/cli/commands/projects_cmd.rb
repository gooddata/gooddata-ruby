# encoding: UTF-8

require_relative '../shared'
require_relative '../../commands/projects'

GoodData::CLI.module_eval do
  desc 'Manage your projects'
  command :projects do |c|
    c.desc "Lists user's projects"
    c.command :list do |list|
      list.action do |global_options, options, _args|
        opts = options.merge(global_options)
        client = GoodData.connect(opts)
        list = GoodData::Command::Projects.list(client: client)
        puts list.map { |p| [p.uri, p.title].join(',') }
      end
    end
  end
end
