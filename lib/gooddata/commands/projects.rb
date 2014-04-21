# encoding: UTF-8

require 'pathname'

module GoodData::Command
  class Projects
    class << self
      def list
        GoodData::Project.all
      end

      # Create new project based on options supplied
      def create(options={})
        title = options[:title]
        summary = options[:summary]
        template = options[:template]
        token = options[:token]

        GoodData::Project.create(:title => title, :summary => summary, :template => template, :auth_token => token)
      end

      # Show existing project
      def show(id)
        GoodData::Project[id]
      end

      # Clone existing project
      def clone(project_id, options)
        with_data = options[:data] || true
        with_users = options[:users] || false
        title = options[:title]
        export = {
          :exportProject => {
            :exportUsers => with_users ? 1 : 0,
            :exportData => with_data ? 1 : 0
          }
        }

        result = GoodData.post("/gdc/md/#{project_id}/maintenance/export", export)
        export_token = result['exportArtifact']['token']
        status_url = result['exportArtifact']['status']['uri']

        state = GoodData.get(status_url)['taskState']['status']
        while state == 'RUNNING'
          sleep 5
          result = GoodData.get(status_url)
          state = result['taskState']['status']
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
        status_url = result['uri']
        state = GoodData.get(status_url)['taskState']['status']
        while state == 'RUNNING'
          sleep 5
          result = GoodData.get(status_url)
          state = result['taskState']['status']
        end
        true
      end

      # Delete existing project
      def delete(project_id)
        p = GoodData::Project[project_id]
        p.delete
      end

      # Get Spec and ID (of project)
      def get_spec_and_project_id(base_path)
        goodfile_path = GoodData::Helpers.find_goodfile(Pathname(base_path))
        fail 'Goodfile could not be located in any parent directory. Please make sure you are inside a gooddata project folder.' if goodfile_path.nil?
        goodfile = JSON.parse(File.read(goodfile_path), :symbolize_names => true)
        spec_path = goodfile[:model] || fail('You need to specify the path of the build spec')
        fail "Model path provided in Goodfile \"#{spec_path}\" does not exist" unless File.exist?(spec_path) && !File.directory?(spec_path)

        spec_path = Pathname(spec_path)

        content = File.read(spec_path)
        spec = if (spec_path.extname == '.rb')
                 eval(content)
               elsif (spec_path.extname == '.json')
                 JSON.parse(spec_path, :symbolize_names => true)
               end
        [spec, goodfile[:project_id]]
      end

      def get_roles(project_id)
        url = "/gdc/projects/#{project_id}/roles"

        res = []

        tmp = GoodData.get(url)
        tmp['projectRoles']['roles'].each do |role_url|
          res << GoodData.get(role_url)
        end

        return res
      end

      # Update project
      def update(options={})
        project = options[:project]
        project_id = project && project.pid
        fail 'You have to provide "project_id". You can either provide it through -p flag or even better way is to fill it in in your Goodfile under key "project_id". If you just started a project you have to create it first. One way might be through "gooddata project build"' if project_id.nil? || project_id.empty?
        GoodData::Model::ProjectCreator.migrate(:spec => options[:spec], :project => project_id)
      end

      # Build project
      def build(options={})
        GoodData::Model::ProjectCreator.migrate(:spec => options[:spec], :token => options[:token])
      end

      def validate(project_id)
        GoodData.with_project(project_id) do |p|
          p.validate
        end
      end

    end
  end
end

