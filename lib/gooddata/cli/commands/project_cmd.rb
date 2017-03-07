# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
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
      c.desc 'Shows users in project'
      c.command :users do |users|
        users.action do |global_options, options, _args|
          opts = options.merge(global_options)
          GoodData::Command::Project.list_users(opts)
        end
      end
    end
  end
end
