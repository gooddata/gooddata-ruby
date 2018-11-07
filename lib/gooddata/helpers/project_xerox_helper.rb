require_relative '../../../spec/lcm/integration/brick_runner'

module GoodData
  module Helpers
    class ProjectXeroxHelper
      def self.clone(source_project, source_connnection_params, target_connection_params, opts = {})
        target_username = target_connection_params[:username] || 'bear@gooddata.com'
        target_password = target_connection_params[:password] || ''
        target_hostname = target_connection_params[:hostname] || 'secure.gooddata.com'
        target_client = GoodData.connect(
          username: target_username,
          password: target_password,
          server: "https://#{target_hostname}",
          verify_ssl: false
        )
        context = {
          source_hostname: source_connnection_params[:hostname] || 'secure.gooddata.com',
          target_hostname: target_hostname,
          source_username: source_connnection_params[:username] || 'bear@gooddata.com',
          target_username: target_username,
          source_password: source_connnection_params[:password] || '',
          target_password: target_password,
          source_pid: source_project.pid,
          project_token: opts[:project_token] || 'pgroup2',
          db_driver: source_project.driver
        }
        BrickRunner.release_brick context: context, template_path: __dir__ + '/xerox_release_brick_params.json.erb', client: target_client
      end
    end
  end
end
