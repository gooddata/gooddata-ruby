require 'pp'
require 'gooddata/helpers'
require 'gooddata/commands/base'
Dir[File.dirname(__FILE__) + '/commands/*.rb'].each { |file| require file }

module Gooddata::Command
  class InvalidCommand < RuntimeError; end
  class InvalidOption < RuntimeError; end
  class CommandFailed  < RuntimeError; end

  extend Gooddata::Helpers

  class << self
    def run(command, args)
      begin
        run_internal command, args.dup
      rescue InvalidCommand
        error "Unknown command. Run 'gooddata help' for usage information."
      rescue InvalidOption
        error "Unknown option."
      rescue RestClient::Unauthorized
        error "Authentication failure"
      rescue RestClient::ResourceNotFound => e
        error extract_not_found(e.http_body)
      rescue RestClient::RequestFailed => e
        error extract_error(e.http_body)
      rescue RestClient::RequestTimeout
        error "API request timed out. Please try again, or contact support@gooddata.com if this issue persists."
      rescue CommandFailed => e
        error e.message
      rescue Interrupt => e
        error "\n[canceled]"
      end
    end

    def run_internal(command, args)
      klass, method = parse(command)
      runner = klass.new(args)
      raise InvalidCommand unless runner.respond_to?(method)
      runner.send(method)
    end

    def parse(command)
      parts = command.split(':')

      parts << :index if parts.size == 1
      raise InvalidCommand if parts.size > 2

      begin
        return Gooddata::Command.const_get(parts[0].capitalize), parts[1]
      rescue NameError
        raise InvalidCommand
      end
    end

    def extract_not_found(body)
      body =~ /^[\w\s]+ not found$/ ? body : "Resource not found"
    end

    def extract_error(body)
      msg = parse_error_json(body) || 'Internal server error'
      msg.split("\n").map { |line| ' !   ' + line }.join("\n")
    end

    def parse_error_json(body)
      begin
          error = JSON.parse(body.to_s)['error']
          return error['message'] if !error['parameters']
          return error['message'] % error['parameters'] rescue error
      rescue JSON::ParserError
          return msg
      end
    end
  end
end
