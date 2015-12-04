# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pathname'
require 'pp'

require_relative '../shared'
require_relative '../../commands/project'

module GoodData
  module CLI
    desc 'Manage your project'
    arg_name 'project_command'

    command :project do |c|
      c.desc 'If you are in a gooddata project blueprint or if you provide a project id it will start an interactive session inside that project'
      c.command :jack_in do |jack|
        jack.action do |global_options, options, _args|
          warn '[DEPRECATION] `gooddata project jack_in` is deprecated.  Please use `gooddata jack_in` instead.'
          opts = options.merge(global_options)
          GoodData::Command::Project.jack_in(opts)
        end
      end
    end

    desc 'If you are in a gooddata project blueprint or if you provide a project id it will start an interactive session inside that project'
    command :jack_in do |jack|
      jack.action do |global_options, options, _args|
        opts = options.merge(global_options)
        GoodData::Command::Project.jack_in(opts)
      end
    end
  end
end
