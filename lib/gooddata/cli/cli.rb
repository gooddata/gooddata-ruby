require 'gli'
require 'pp'

# Define GoodData::CLI as GLI Wrapper
module GoodData
  include GLI::App

  # Require shared part of GLI::App - flags, meta, etc
  require File.join(File.dirname(__FILE__), 'shared.rb')

  Dir[File.dirname(__FILE__) + '/commands/**/*_cmd.rb'].each do |file|
    require file
  end

  GLI::App.commands_from(File.join(File.dirname(__FILE__), 'commands'))

  # Require Hooks
  require File.join(File.dirname(__FILE__), 'hooks')

  class CLI
    def self.init

    end

    def self.main(args = ARGV)
      run(args)
    end
  end
end

if __FILE__ == $0
  GoodData::CLI::init()
  GoodData::CLI::main()
end