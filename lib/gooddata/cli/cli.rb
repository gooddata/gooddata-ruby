require 'pp'

# Define GoodData::CLI as GLI Wrapper
module GoodData
  class CLI
    def self.init
      # Require shared part of GLI::App - flags, meta, etc
      require File.join(File.dirname(__FILE__), 'shared.rb')

      # Require command implementations
      Dir[File.dirname(__FILE__) + '/commands/**/*_cmd.rb'].each do |file|
        pp file
        require file
      end

      # Require Hooks
      require File.join(File.dirname(__FILE__), 'hooks')
    end

    def self.main(args = ARGV)
      exit run(args)
    end
  end
end

GoodData::CLI::init()

if __FILE__ == $0
  exit run(ARGV)
end