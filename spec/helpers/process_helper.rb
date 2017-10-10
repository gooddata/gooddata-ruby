# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

require_relative '../environment/environment'

GoodData::Environment.load

module GoodData
  module Helpers
    module ProcessHelper
      include GoodData::Environment::ProcessHelper

      class << self
        def remove_old_processes(project)
          processes = project.processes
          processes.pmap do |process|
            next if process.obj_id == GoodData::Environment::ProcessHelper::PROCESS_ID
            puts "Deleting #{process.inspect}"
            process.delete
          end
        end
      end
    end
  end
end
