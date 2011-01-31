module GoodData::Command

  # Initializes GoodData connection with credentials loaded from
  # ~/.gooddata. If the file doesn't exist or doesn't contain
  # necessary information, a command line prompt will be issued
  # using the GoodData::Command::Base#ask method
  #
  def self.connect
    GoodData::Command.run_internal('auth:connect', [])
  end

  class Base
    include GoodData::Helpers

    attr_accessor :args

    def initialize(args)
      @args = args
    end

    def connect
      @connected ||= GoodData::Command.connect
      GoodData.connection
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
            answer = get_answer "#{question} [#{options[:answers].join(',')}]? ", options[:secret]
          end
        else
          question = "#{question} [#{options[:default]}]" if options[:default]
          answer = get_answer "#{question}: ", options[:secret], options[:default]
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

    private

    def get_answer(question, secret, default = nil)
      print question
      system "stty -echo" if secret
      answer = $stdin.gets.chomp
      system "stty echo" if secret
      answer = default if answer.empty? && default
      answer
    end
  end
end
