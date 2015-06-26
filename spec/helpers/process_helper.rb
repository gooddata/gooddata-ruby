# encoding: UTF-8

# Global requires
require 'multi_json'
require 'pmap'

# Local requires
require 'gooddata/models/models'

require_relative '../environment/environment'

GoodData::Environment.load

module GoodData::Helpers
  module ProcessHelper
    include GoodData::Environment::ProcessHelper

    class << self
      def remove_old_processes(project)
        processes = project.processes
        processes.pmap do |process|
          next if process.obj_id == PROCESS_ID
          puts "Deleting #{process.inspect}"
          process.delete
        end
      end
    end
  end
end
