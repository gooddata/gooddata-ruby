# encoding: UTF-8

require 'pp'

require_relative '../shared'
require_relative '../../commands/profile'

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