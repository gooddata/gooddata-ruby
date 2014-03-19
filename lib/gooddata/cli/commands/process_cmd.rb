# encoding: UTF-8

require 'pp'

require File.join(File.dirname(__FILE__), '../shared')
require File.join(File.dirname(__FILE__), '../../commands/process')

GoodData::CLI.module_eval do

  desc 'Work with deployed processes'
  arg_name 'Describe arguments to list here'
  command :process do |c|

    c.desc 'Use when you need to redeploy a specific process'
    c.default_value nil
    c.flag :process_id

    c.desc 'Specify directory for deployment'
    c.default_value nil
    c.flag :dir

    c.desc 'Specify type of deployment'
    c.default_value nil
    c.flag :type

    c.desc 'Specify name of deployed process'
    c.default_value nil
    c.flag :name

    c.desc "Lists all user's processes deployed on the plaform"
    c.command :list do |list|
      list.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        pp GoodData::Command::Process.list(options.merge(global_options))
      end
    end

    c.desc 'Gives you some basic info about the process'
    c.command :get do |get|
      get.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        pp GoodData::Command::Process.get(options.merge(global_options))
      end
    end

    c.desc 'Deploys provided directory to the server'
    c.command :deploy do |deploy|
      deploy.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        pp GoodData::Command::Process.deploy(options[:dir], options.merge(global_options))
      end
    end
  end
end