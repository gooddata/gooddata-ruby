# encoding: UTF-8

require 'pp'
require 'readline'

require_relative '../core/core'
require_relative '../cli/cli'

module GoodData
  # Interactive shell
  class Shell
    # Constructs prompt for usage
    def prompt
      return '> '
    end

    # Prints basic shell usage
    def print_usage
      puts "Type 'help' for usage info"
      puts "Type '(q)uit', or 'e(x)it' for quit"
    end

    # Processes one line
    def process_line(line)
      argv = line.split
      res = GoodData::CLI.main(argv)
      puts res
      res
    end

    # Runs shell loop
    def run(opts={}, args=[])
      while (line = Readline.readline(prompt, true))
        if line.empty?
          print_usage
          next
        end

        if ['x', 'exit', 'q', 'quit'].include?(line.downcase)
          break
        end

        process_line(line)
      end
    end
  end
end