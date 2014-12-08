# encoding: UTF-8

# Global requires
require 'multi_json'
require 'pmap'

# Local requires
require 'gooddata/models/models'

module ProcessHelper
  PROCESS_ID = 'dc143d80-58a1-4acd-96b6-8d11fc4571de'
  DEPLOY_NAME = 'graph'

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
