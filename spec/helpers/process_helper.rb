# encoding: UTF-8

# Global requires
require 'multi_json'
require 'pmap'

# Local requires
require 'gooddata/models/models'

module ProcessHelper
  PROCESS_ID = '81fa71a4-69fd-4c58-aa09-66e7f53f4647'
  DEPLOY_NAME = 'graph.grf'

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
