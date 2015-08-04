# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../shared'
require_relative '../../commands/projects'

GoodData::CLI.module_eval do
  desc 'Manage your projects'
  command :projects do |c|
    c.desc "Lists user's projects"
    c.command :list do |list|
      list.action do |global_options, options, _args|
        opts = options.merge(global_options)
        client = GoodData.connect(opts)
        list = GoodData::Command::Projects.list(client: client)
        puts list.map { |p| [p.uri, p.title].join(',') }
      end
    end
  end
end
