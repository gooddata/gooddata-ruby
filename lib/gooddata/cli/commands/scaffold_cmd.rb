# encoding: UTF-8

require 'pp'

require_relative '../shared'
require_relative '../../commands/scaffold'

GoodData::CLI.module_eval do
  desc 'Scaffold things'
  arg_name 'show'
  command :scaffold do |c|
    c.desc 'Scaffold a gooddata project blueprint'
    c.command :project do |project|
      project.action do |_global_options, _options, args|
        name = args.first
        fail 'Name of the project has to be provided' if name.nil? || name.empty?
        GoodData::Command::Scaffold.project(name)
      end
    end

    c.desc 'Scaffold a gooddata ruby brick. This is a piece of code that you can run on our platform'
    c.command :brick do |brick|
      # brick.arg_name 'name'
      brick.action do |_global_options, _options, args|
        name = args.first
        fail 'Name of the brick has to be provided' if name.nil? || name.empty?
        GoodData::Command::Scaffold.brick(name)
      end
    end
  end
end
