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
          id = options[:process_id]
          fail 'Unspecified process id' if id.nil?

          GoodData.with_project(options[:project_id]) do
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
          verbose = options[:verbose]

          def deploy(dir, options = {})
            options[:verbose] || false

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
        end
      end
    end
  end
end