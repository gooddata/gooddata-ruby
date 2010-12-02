module Gooddata::Command
  class Help < Base
    class HelpGroup < Array
      attr_reader :title

      def initialize(title)
        @title = title
      end

      def command(name, description)
        self << [name, description]
      end

      def space
        self << ['', '']
      end
    end

    class << self
      def groups
        @groups ||= []
      end

      def group(title, &block)
        groups << begin
          group = HelpGroup.new(title)
          yield group
          group
        end
      end

      def create_default_groups!
        group 'General Commands' do |group|
          group.command 'help',                         'show this usage'
          group.command 'version',                      'show the gem version'
          group.space
          group.command 'api',                          'general info about the current GoodData API version'
          group.command 'api:test',                     'test you credentials and the connection to GoodData server'
          group.command 'api:get',                      'issue a generic GET request to the GoodData API'
          group.space
          group.command 'auth:store',                   'save your GoodData credentials and we won\'t ask you for them ever again'
          group.command 'auth:unstore',                 'remove the saved GoodData credentials from your computer'
          group.space
          group.command 'datasets',                     'list remote data sets in the project specified via --project'
          group.command 'datasets:describe',            'describe a local data set and save the description in a JSON file'
          group.space
          group.command 'profile',                      'show your GoodData profile'
          group.space
          group.command 'projects',                     'list available projects'
          group.command 'projects:create',              'create new project'
          group.command 'projects:show <key>',          'show project details'
          group.command 'projects:delete <key> [...]',  'delete one or more existing projects'
        end

        group 'General Options' do |group|
          group.command '--log-level <level>', 'Set the log level (fatal, error, warn [default], info, debug)'
          group.command '--project <project_id>', 'Set the working remote project identified by an URI or project ID'
        end
      end
    end

    def index
      puts usage
    end

    def version
      puts Gooddata::Client.version
    end

    def usage
      longest_command_length = self.class.groups.map do |group|
        group.map { |g| g.first.length }
      end.flatten.max

      s = StringIO.new
      s << <<-EOT
=== Usage

gooddata COMMAND [options]

EOT

      self.class.groups.inject(s) do |output, group|
        output.puts "=== %s" % group.title
        output.puts

        group.each do |command, description|
          if command.empty?
            output.puts
          else
            output.puts "%-*s # %s" % [longest_command_length, command, description]
          end
        end

        output.puts
        output
      end.string
    end
  end
end

Gooddata::Command::Help.create_default_groups!
