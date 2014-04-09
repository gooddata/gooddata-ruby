# encoding: UTF-8

require 'pp'
require 'readline'

require_relative '../core/core'
require_relative '../cli/cli'

module GoodData
  # Interactive shell
  class Shell
    EXCLUDE_CMDS = [:_doc]

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

    # Completes line
    # TODO: Rewrite to recursive version to support nested commands automagically
    def completion(line)
      tokens = line.split
      if(tokens.length < 2 && !line.ends_with?(' '))
        return completion_global(line)
      end

      return completion_cmd(line)
    end

    # Runs shell loop
    def run(opts={}, args=[])
      # Readline.completion_append_character = " "
      Readline.completion_proc = Proc.new { |line| completion(line) }
      Readline.basic_word_break_characters = ''

      res = completion('api ')

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

    private

    # Autocomplete line using global commands
    def completion_global(line)
      GoodData::CLI.commands.keys.select do |cmd|
        !EXCLUDE_CMDS.include?(cmd) && cmd.to_s.start_with?(line)
      end
    end

    # Autocompletes line using command specific options
    def completion_cmd(line)
      tokens = line.split(' ')

      cmd_name = tokens[0].to_sym
      cmd = GoodData::CLI.commands[cmd_name]

      return [] if cmd.nil?

      res = []
      filter = tokens.length > 1 ? tokens[1] : ''
      cmd.commands.keys.each do |cmd_key|
        res << "#{cmd_name} #{cmd_key}" if cmd_key.to_s.start_with? filter
      end
      res
    end

  end
end