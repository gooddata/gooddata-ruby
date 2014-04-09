# encoding: UTF-8

require 'pp'

require_relative '../shared'
require_relative '../../shell/shell'

GoodData::CLI.module_eval do
  desc 'Interactive Shell'
  arg_name 'shell'
  command :shell do |shell_cmd|
    shell_cmd.action do |global_options, options, args|
      opts = options.merge(global_options)

      shell = GoodData::Shell.new
      shell.run(opts, args)
    end
  end
end
