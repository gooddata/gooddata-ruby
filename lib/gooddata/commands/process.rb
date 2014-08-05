# encoding: UTF-8

require 'pathname'

require_relative '../core/core'

module GoodData
  module Command
    class Process
      class << self
        def list(options = {})
          GoodData.with_project(options[:project_id]) do
            GoodData::Process[:all]
          end
        end

        def get(options = {})
          pid = options[:project_id]
          fail ArgumentError, 'None or invalid project_id specified' if pid.nil? || pid.empty?

          id = options[:process_id]
          fail ArgumentError, 'None or invalid process_id' if id.nil? || id.empty?

          GoodData.with_project(pid) do
            GoodData::Process[id]
          end
        end

        def delete(process_id, options = {})
          GoodData.with_project(options[:project_id]) do
            process = GoodData::Process[process_id]
            process.delete
          end
        end

        # TODO: check files_to_exclude param. Does it do anything? It should check that in case of using CLI, it makes sure the files are not deployed
        def deploy(dir, options = {})
          GoodData.with_project(options[:project_id]) do
            params = options[:params].nil? ? [] : [options[:params]]
            GoodData::Process.deploy(dir, options.merge(:files_to_exclude => params))
          end
        end

        def execute_process(process_id, executable, options = {})
          GoodData.with_project(options[:project_id]) do
            process = GoodData::Process[process_id]
            process.execute_process(executable, options)
          end
        end

        def run(dir, executable, options = {})
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
