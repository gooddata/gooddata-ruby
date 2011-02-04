module GoodData
  module Command
    class Projects < Base
      def list
        connect
        Project.all.each do |project|
          puts "%s  %s" % [project.uri, project.title]
        end
      end
      alias :index :list

      def create
        connect

        title = ask "Project name"
        summary = ask "Project summary"
        template = ask "Project template", :default => ''

        project = Project.create :title => title, :summary => summary, :template => template

        puts "Project '#{project.title}' with id #{project.uri} created successfully!"
      end

      def show
        id = args.shift rescue nil
        raise(CommandFailed, "Specify the project key you wish to show.") if id.nil?
        connect
        pp Project[id].to_json
      end

      def delete
        raise(CommandFailed, "Specify the project key(s) for the project(s) you wish to delete.") if args.size == 0
        connect
        while args.size > 0
          id = args.shift
          project = Project[id]
          ask "Do you want to delete the project '#{project.title}' with id #{project.uri}", :answers => %w(y n) do |answer|
            case answer
            when 'y' then
              puts "Deleting #{project.title}..."
              project.delete
              puts "Project '#{project.title}' with id #{project.uri} deleted successfully!"
            when 'n' then
              puts "Aborting..."
            end
          end
        end
      end
    end
  end
end