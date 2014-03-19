# encoding: UTF-8

require File.join(File.dirname(__FILE__), '../shared')
require File.join(File.dirname(__FILE__), '../../commands/auth')

GoodData::CLI.module_eval do

  desc 'Work with your locally stored credentials'
  command :auth do |c|

    c.desc 'Store your credentials to ~/.gooddata so client does not have to ask you every single time'
    c.command :store do |store|
      store.action do |global_options, options, args|
        GoodData::Command::Auth.store
      end
    end
  end

end