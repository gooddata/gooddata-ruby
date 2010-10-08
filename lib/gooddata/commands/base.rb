module Gooddata::Command
  class Base
    include Gooddata::Helpers

    attr_accessor :args

    def initialize(args)
      @args = args
    end

    def gooddata
      @gooddata ||= Gooddata::Command.run_internal('auth:client', args)
    end

    def extract_option(options, default=true)
      values = options.is_a?(Array) ? options : [options]
      return unless opt_index = args.select { |a| values.include? a }.first
      opt_position = args.index(opt_index) + 1
      if args.size > opt_position && opt_value = args[opt_position]
        if opt_value.include?('--')
          opt_value = nil
        else
          args.delete_at(opt_position)
        end
      end
      opt_value ||= default
      args.delete(opt_index)
      block_given? ? yield(opt_value) : opt_value
    end

    def ask(question, options = {})
      begin
        if options.has_key? :answers
          answer = nil
          while !options[:answers].include?(answer)
            print "#{question} [#{options[:answers].join(',')}]? "
            system "stty -echo" if options[:secret]
            answer = $stdin.gets.chomp
            system "stty echo" if options[:secret]
          end
        else
          print "#{question}: "
          system "stty -echo" if options[:secret]
          answer = $stdin.gets.chomp
          system "stty echo" if options[:secret]
        end
        puts if options[:secret] # extra line-break
      rescue NoMethodError, Interrupt => e
        system "stty echo"
        puts e
        exit
      end

      if block_given?
        yield answer
      else
        return answer
      end
    end
  end
end
