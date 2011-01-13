module GoodData::Command
  class Projects < Base
    def list
      gooddata.projects.each do |project|
        puts "%s  %s" % [project.uri, project.name]
      end
    end
    alias :index :list

    def create
      name = ask "Project name"
      summary = ask "Project summary"
      template = ask "Project template", :default => '/projectTemplates/empty'

      project = gooddata.projects.create :name => name, :summary => summary, :template => template

      puts "Project '#{project.name}' with id #{project.uri} created successfully!"
    end

    def show
      id = args.shift rescue nil
      raise(CommandFailed, "Specify the project key you wish to show.") if id.nil?
      pp gooddata.find_project(id).to_json
    end

    def delete
      raise(CommandFailed, "Specify the project key(s) for the project(s) you wish to delete.") if args.size == 0
      while args.size > 0
        id = args.shift
        project = gooddata.find_project(id)
        ask "Do you want to delete the project '#{project.name}' with id #{project.uri}", :answers => %w(y n) do |answer|
          case answer
          when 'y' then
            puts "Deleting #{project.name}..."
            project.delete
            puts "Project '#{project.name}' with id #{project.uri} deleted successfully!"
          when 'n' then
            puts "Aborting..."
          end
        end
      end
    end
  end
end