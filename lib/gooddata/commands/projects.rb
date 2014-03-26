module GoodData::Command
  class Projects

    def self.list
      GoodData::Project.all
    end

    def self.create(options={})
      title = options[:title]
      summary = options[:summary]
      template = options[:template]
      token = options[:token]

      GoodData::Project.create(:title => title, :summary => summary, :template => template, :auth_token => token)
    end

    def self.show(id)
      GoodData::Project[id]
    end

    def self.clone(project_id, options)
      with_data   = options[:with_data]
      with_users  = options[:with_users]
      title = options[:title]
      
      export = {
        :exportProject => {
          :exportUsers => with_users ? 1 : 0,
          :exportData => with_data ? 1 : 0
        }
      }
      
      result = GoodData.post("/gdc/md/#{project_id}/maintenance/export", export)
      export_token = result["exportArtifact"]["token"]
      status_url = result["exportArtifact"]["status"]["uri"]

      state = GoodData.get(status_url)["taskState"]["status"]
      while state == "RUNNING"
        sleep 5
        result = GoodData.get(status_url) 
        state = result["taskState"]["status"]
      end

      old_project = GoodData::Project[project_id]
      project_uri = self.create(options.merge({:title => "Clone of #{old_project.title}"}))
      new_project = GoodData::Project[project_uri]

      import = {
        :importProject => {
          :token => export_token
        }
      }
      result = GoodData.post("/gdc/md/#{new_project.obj_id}/maintenance/import", import)
      status_url = result["uri"]
      state = GoodData.get(status_url)["taskState"]["status"]
      while state == "RUNNING"
        sleep 5
        result = GoodData.get(status_url) 
        state = result["taskState"]["status"]
      end
      true
    end

    def self.delete(project_id)
      p = GoodData::Project[project_id]
      p.delete
    end

    def self.get_spec_and_project_id(base_path)
      goodfile_path = GoodData::Helpers.find_goodfile(Pathname(base_path))
      fail "Goodfile could not be located in any parent directory. Please make sure you are inside a gooddata project folder." if goodfile_path.nil?
      goodfile = MultiJson.load(File.read(goodfile_path), :symbolize_keys => true)
      spec_path = goodfile[:model] || fail("You need to specify the path of the build spec")
      fail "Model path provided in Goodfile \"#{spec_path}\" does not exist" unless File.exist?(spec_path) && !File.directory?(spec_path)

      spec_path = Pathname(spec_path)

      content = File.read(spec_path)
      spec = if (spec_path.extname == ".rb")
               eval(content)
             elsif (spec_path.extname == ".json")
               MultiJson.load(spec_path, :symbolize_keys => true)
             end
      [spec, goodfile[:project_id]]
    end

    def self.update(options={})
      project = options[:project]
      project_id = project && project.pid
      fail "You have to provide 'project_id'. You can either provide it through -p flag or even better way is to fill it in in your Goodfile under key \"project_id\". If you just started a project you have to create it first. One way might be through \"gooddata project build\"" if project_id.nil? || project_id.empty?
      GoodData::Model::ProjectCreator.migrate(:spec => options[:spec], :project => project_id)
    end

    def self.build(options={})
      GoodData::Model::ProjectCreator.migrate(:spec => options[:spec], :token => options[:token])
    end

  end
end

# module GoodData
#   module Command
#     class Projects
#       class << self
#         def list
#           Project.all
#         end
#         alias :index :list
# 
#       def create
#         title = ask "Project name"
#         summary = ask "Project summary"
#         template = ask "Project template", :default => ''
# 
#         project = Project.create :title => title, :summary => summary, :template => template
# 
#         puts "Project '#{project.title}' with id #{project.uri} created successfully!"
#       end
# 
#       def show
#         id = args.shift rescue nil
#         raise(CommandFailed, "Specify the project key you wish to show.") if id.nil?
#         connect
#         pp Project[id].to_json
#       end
# 
#       def delete
#         raise(CommandFailed, "Specify the project key(s) for the project(s) you wish to delete.") if args.size == 0
#         connect
#         while args.size > 0
#           id = args.shift
#           project = Project[id]
#           ask "Do you want to delete the project '#{project.title}' with id #{project.uri}", :answers => %w(y n) do |answer|
#             case answer
#             when 'y' then
#               puts "Deleting #{project.title}..."
#               project.delete
#               puts "Project '#{project.title}' with id #{project.uri} deleted successfully!"
#             when 'n' then
#               puts "Aborting..."
#             end
#           end
#         end
#       end
#     end
#   end
# end
