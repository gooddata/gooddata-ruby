# encoding: UTF-8

require_relative '../shared'
require_relative '../../commands/auth'

GoodData::CLI.module_eval do
  desc 'Work with your locally stored credentials'
  command :auth do |c|
    c.desc 'Store your credentials to ~/.gooddata so client does not have to ask you every single time'
    c.command :store do |store|
      store.action do |_global_options, _options, _args|
        GoodData::Command::Auth.store
      end
    end
  end
end
