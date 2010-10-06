require 'rubygems'
require 'optparse'
require 'parseconfig'
require 'pp'
require File.dirname(__FILE__) + '/good_data/base'

module GooddataCli
  class << self
    NAME = "gooddata-ruby"
    CONFIG_FILE = '~/.gdr'

    def run
      parse_config_file
      parse_command_line_args
    end

    private

    def parse_config_file
      if File.exist? File.expand_path(CONFIG_FILE)
        @config = ParseConfig.new(File.expand_path(CONFIG_FILE)).params
      end
      @config = { 'mode' => :none, 'log_level' => :warn }.merge(@config || {})
    end

    def parse_command_line_args
      options = OptionParser.new do |opts|
        opts.banner = "Usage: gdr [mode] [options]"

        opts.separator ''
        opts.separator 'Project related modes:'
        opts.on('-l', '--list-projects',
                'List available projects')                                    { @config['mode'] = :list_projects }
        opts.on('-c', '--create-project',
                'Create new project')                                         { @config['mode'] = :create_project }
        opts.on('-s', '--show-project ID',
                'Show project details')                                       { |id| @config['mode'] = :show_project; @config['project_id'] = id }
        opts.on('-D', '--delete-project ID',
                'Delete an existing project')                                 { |id| @config['mode'] = :delete_project; @config['project_id'] = id }

        opts.separator ''
        opts.separator 'Profile related modes:'
        opts.on('--show-profile',
                'Show your GoodData profile')                                 { @config['mode'] = :show_profile }

        opts.separator ''
        opts.separator 'Other modes:'
        opts.on('-v', '--version',
                'Show version')                                               { output_version; exit 0 }
        opts.on('-h', '--help',
                'Show this message')                                          { puts opts; exit 0 }
        opts.on('-t', '--test',
                'Test you credentials and the connection to GoodData server') { @config['mode'] = :test_connection }
        opts.on('--api-info',
                'General info about the current GoodData API version')        { @config['mode'] = :api_info }
        opts.on('--write-settings',
                'Write default settings to a convenient ~/.gdr file')         { @config['mode'] = :write_settings }

        opts.separator ''
        opts.separator 'Login options:'
        opts.on('-u', '--username USERNAME',
                'Set GoodData username')                                      { |username| @config['username'] = username }
        opts.on('-p', '--password PASSWORD',
                'Set GoodData password')                                      { |password| @config['password'] = password }

        opts.separator ''
        opts.separator 'Other options:'
        opts.on('--log-level LEVEL',
                [:fatal, :error, :warn, :info, :debug],
                'Set the log level. Possible levels are:',
                'fatal, error, warn (default), info, debug')                  { |level| @config['log_level'] = level }

        opts.separator ''
        opts.separator 'See http://github.com/gooddata/gooddata-ruby for details'
      end
      options.parse!

      case @config['mode']
      when :test_connection then
        ensure_credentials
        test_connection
      when :show_profile then
        ensure_credentials
        show_profile
      when :list_projects then
        ensure_credentials
        list_projects
      when :create_project then
        ensure_credentials
        create_project
      when :show_project then
        ensure_credentials
        show_project(@config['project_id'])
      when :delete_project then
        ensure_credentials
        delete_project(@config['project_id'])
      when :api_info then
        ensure_credentials
        api_info
      when :write_settings then
        write_settings
      when :none then
        puts options
      else
        raise "Unknown mode #{@config['mode']}"
      end
    end

    def output_version
      version = nil
      File.open(File.dirname(__FILE__) + '/../VERSION') { |f| version = f.gets }
      puts "#{NAME} v#{version}"
    end

    def test_connection
      gd = GoodData::Base.new @config
      GoodData::Connection.instance.connect!
      if GoodData::Connection.instance.logged_in?
        puts "Succesfully logged in as #{gd.profile.user}"
      else
        puts "Unable to log in to GoodData server!"
      end
    end

    def show_profile
      gd = GoodData::Base.new @config
      pp GoodData::Profile.load.to_json
    end

    def list_projects
      gd = GoodData::Base.new @config
      gd.projects.each do |project|
        puts "%6i  %s" % [project.id, project.name]
      end
    end

    def create_project
      name = ask "Project name"
      summary = ask "Project summary"

      gd = GoodData::Base.new @config
      project = gd.projects.create :name => name, :summary => summary

      puts "Project '#{project.name}' with id #{project.id} created successfully!"
    end

    def show_project(id)
      gd = GoodData::Base.new @config
      project = GoodData::Project.find(id)
      pp project.to_json
    end

    def delete_project(ids)
      gd = GoodData::Base.new @config
      ids.to_s.split(',').each do |id|
        project = GoodData::Project.find(id)
        ask "Do you want to delete the project '#{project.name}' with id #{project.id}", :answers => %w(y n) do |answer|
          case answer
          when 'y' then
            puts "Deleting #{project.name}..."
            project.delete
            puts "Project '#{project.name}' with id #{project.id} deleted successfully!"
          when 'n' then
            puts "Aborting..."
          end
        end
      end
    end

    def api_info
      gd = GoodData::Base.new @config
      json = gd.release_info
      puts "GoodData API"
      puts "  Version: #{json['releaseName']}"
      puts "  Released: #{json['releaseDate']}"
      puts "  For more info see #{json['releaseNotesUri']}"
    end

    def write_settings
      username = ask "GoodData username"
      password = ask "GoodData password", :secret => true

      ovewrite = if File.exist?(File.expand_path(CONFIG_FILE))
        ask "The gdr settings file already exist at #{CONFIG_FILE}. Overwrite", :answers => %w(y n)
      else
        'y'
      end

      if ovewrite == 'y'
        File.open(File.expand_path(CONFIG_FILE), 'w', 0600) do |f|
          f.puts "username=#{username}"
          f.puts "password=#{password}"
        end
      else
        puts 'Aborting...'
      end
    end

    def ensure_credentials
      @config['username'] = ask("Username") unless @config.has_key? 'username'
      @config['password'] = ask("Password", :secret => true) unless @config.has_key? 'password'
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