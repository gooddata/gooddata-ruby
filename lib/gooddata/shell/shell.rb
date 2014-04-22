# encoding: UTF-8

require 'pp'
require 'readline'

require_relative '../core/core'
require_relative '../cli/cli'

module GoodData
  # Interactive shell
  class Shell
    EXCLUDE_CMDS = [:_doc, :console, :shell]
    GLOBAL_OPTS = [:P, :U, :p, :s, :t, :w]

    # Constructs prompt for usage
    def prompt
     return '> '
    end

    # Prints basic shell usage
    def print_usage
      puts "Type 'help' for usage info"
      puts "Type '(q)uit', or 'e(x)it' for quit"
    end

    def hack_global_opts(opts)
      res = ''
      GLOBAL_OPTS.each do |opt_name|
        res = res + " -#{opt_name.to_s} #{opts[opt_name]}" if (opts[opt_name])
      end
      res
    end

    # Processes one line
    def process_ruby_cmd(line, opts={})
      hacked_line = hack_global_opts(opts) + ' ' + line
      argv = hacked_line.split

      GoodData.logger.info hacked_line

      res = GoodData::CLI.main(argv, opts)
      puts res
      res
    end

    def process_os_cmd(line)
      bash_cmd = line
      bash_cmd.slice!(0)
      system bash_cmd
      # TODO: puts exit code to be consistent with interactive commands
    end

    def process_cmd(line, opts = {}, args = [])
      if line.empty?
        print_usage
        return true
      end

      if EXCLUDE_CMDS.include?(line.to_sym)
        puts "Dear hacker, running '#{line}' in shell is disabled"
        return true
      end

      if line[0] == '!'
        return process_os_cmd(line)
        return true
      end

      if ['x', 'exit', 'q', 'quit'].include?(line.downcase)
        return false
      end

      return process_ruby_cmd(line, opts)
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

      # TODO: Investigate why this is not working as expected
      GLI::AppSupport.override_defaults_based_on_config(opts)

      while (line = Readline.readline(prompt, true))
        break if process_cmd(line, opts, args) == false
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