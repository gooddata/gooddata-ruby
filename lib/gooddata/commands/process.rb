# encoding: UTF-8

require 'pathname'

require_relative '../core/core'

module GoodData
  module Command
    class Process
      class << self
        def list(options = { :client => GoodData.connection, :project => GoodData.project })
          GoodData::Process[:all, options]
        end

        def get(options = {})
          pid = options[:project_id]
          fail ArgumentError, 'None or invalid project_id specified' if pid.nil? || pid.empty?

          id = options[:process_id]
          fail ArgumentError, 'None or invalid process_id' if id.nil? || id.empty?
          c = options[:client]
          c.with_project(pid) do |project|
            project.processes(id)
          end
        end

        def delete(process_id, options = { :client => GoodData.connection, :project => GoodData.project })
          c = options[:client]
          pid = options[:project_id]
          process = c.with_project(pid) do |project|
            project.processes(process_id)
          end
          process.delete
        end

        # TODO: check files_to_exclude param. Does it do anything? It should check that in case of using CLI, it makes sure the files are not deployed
        def deploy(dir, options = { :client => GoodData.connection, :project => GoodData.project })
          params = options[:params].nil? ? [] : [options[:params]]
          c = options[:client]
          pid = options[:project_id]
          c.with_project(pid) do |project|
            project.deploy_process(dir, options.merge(:files_to_exclude => params))
          end
        end

        def execute_process(process_id, executable, options = { :client => GoodData.connection, :project => GoodData.project })
          process = GoodData::Process[process_id, options]
          process.execute_process(executable, options)
        end

        def run(dir, executable, options = { :client => GoodData.connection, :project => GoodData.project })
          verbose = options[:v]
          dir = Pathname(dir)
          name = options[:name] || "Temporary deploy[#{dir}][#{options[:project_name]}]"
          GoodData::Process.with_deploy(dir, options.merge(:name => name, :project_id => ProjectHelper::PROJECT_ID)) do |process|
            puts HighLine.color('Executing', HighLine::BOLD) if verbose
            process.execute(executable, options)
          end
        end
      end
    end
  end
end
