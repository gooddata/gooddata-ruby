# encoding: UTF-8

require_relative '../shared'
require_relative '../../commands/projects'

GoodData::CLI.module_eval do

  desc 'Manage your projects'
  command :projects do |c|

    c.desc "Lists user's projects"
    c.command :list do |list|
      list.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        list = GoodData::Command::Projects.list()
        puts list.map { |p| [p.uri, p.title].join(',') }
      end
    end
  end
end