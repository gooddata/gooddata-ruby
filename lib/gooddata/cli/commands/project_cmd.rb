# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pathname'
require 'json'
require 'tty-spinner'

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
          spinner = TTY::Spinner.new ":spinner Listing users"
          spinner.auto_spin
          res = GoodData::Command::Project.list_users(opts)
          spinner.stop
          res
        end
      end

      c.desc 'Create new project'
      c.command :create do |create|
        create.action do |global_options, options, _args|
          opts = options.merge(global_options)
          token = opts[:token]
          title = opts[:title] || 'New project'
          driver = opts[:driver] || 'Pg'
          spinner = TTY::Spinner.new ":spinner Creating project"
          spinner.auto_spin
          client = GoodData.connect(opts)
          res = GoodData::Command::Project.create(token: token, title: title, driver: driver, client: client)
          spinner.stop
          puts res.to_json
        end
      end
    end
  end
end
