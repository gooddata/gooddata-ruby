# Copyright (c) 2010-2019 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../shared'
require_relative '../../commands/api'

require 'json'
require 'tty-spinner'

module GoodData
  module CLI
    desc 'Manage processes (ETLs, Ruby bricks..)'
    command :process do |c|
      c.desc 'Create a new process'
      c.command :create do |s|
        s.desc 'Create a new process from a webdav or gerrit appstore path'
        s.command :from_path do |cs|
          cs.action do |global_options, options, args|
            opts = options.merge(global_options)
            path = args.first
            spinner = TTY::Spinner.new ":spinner Creating process"
            spinner.auto_spin
            client = GoodData.connect opts
            project = client.projects(opts[:project_id])
            res = GoodData::Process.deploy(path, project: project, client: client)
            spinner.stop
            puts res.to_json
          end
        end

        s.desc 'Create a new process as a pluggable component'
        s.command :as_component do |ac|
          ac.action do |global_options, options, args|
            opts = options.merge(global_options)
            file = args.first
            fail 'Deploying a component requires a JSON formatted payload as a parameter' unless file

            payload = JSON.parse(File.read(file))
            spinner = TTY::Spinner.new ":spinner Creating process"
            spinner.auto_spin
            client = GoodData.connect opts
            project = client.projects(opts[:project_id])
            res = GoodData::Process.deploy_component(payload, project: project, client: client)
            spinner.stop
            puts res.to_json
          end
        end
      end
    end
  end
end
