# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pathname'
require 'pp'

require_relative '../shared'
require_relative '../../commands/domain'

module GoodData
  module CLI
    desc 'Manage your domain'
    arg_name 'domain_command'

    command :domain do |c|
      c.desc 'Shows users in domain'
      c.command :users do |users|
        users.action do |global_options, options, args|
          opts = options.merge(global_options)
          GoodData::Command::Domain.list_users(args[0], opts)
        end
      end
    end
  end
end
