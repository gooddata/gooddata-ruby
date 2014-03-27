# encoding: UTF-8

require 'gli'
require 'pp'

# Define GoodData::CLI as GLI Wrapper
module GoodData
  module CLI
    include GLI::App

    # Require shared part of GLI::App - flags, meta, etc
    require_relative 'shared.rb'

    # Require Hooks
    require_relative 'hooks.rb'

    GLI::App.commands_from(File.join(File.dirname(__FILE__), 'commands'))

    def self.main(args = ARGV)
      run(args)
    end
  end
end

if __FILE__ == $0
  GoodData::CLI.main(ARGV)
end