# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../shared'
require_relative '../../commands/project'
require_relative '../../commands/role'
require_relative '../../commands/user'

GoodData::CLI.module_eval do
  desc 'User management'
  command :user do |c|
    c.desc 'Show your profile'
    c.command :show do |show|
      show.action do |global_options, options, _args|
        opts = options.merge(global_options)
        client = GoodData.connect(opts)
        pp GoodData::Command::User.show(client: client)
      end
    end
  end
end
