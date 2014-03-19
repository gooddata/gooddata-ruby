# encoding: UTF-8

require 'pp'

require File.join(File.dirname(__FILE__), '../shared')
require File.join(File.dirname(__FILE__), '../../commands/profile')

GoodData::CLI.module_eval do

  desc 'Describe add here'
  arg_name 'show'
  command :profile do |c|

    c.desc 'Show your profile'
    c.command :show do |show|
      show.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        pp GoodData::Command::Profile.show()
      end
    end
  end

end