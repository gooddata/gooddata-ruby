# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../shared'
require_relative '../../commands/domain'

GoodData::CLI.module_eval do
  desc 'Manage domain'
  command :domain do |c|
    c.desc 'Add user to domain'
    c.command :add_user do |add_user|
      add_user.action do |global_options, options, args|
        opts = options.merge(global_options)
        client = GoodData.connect(opts)

        domain = args[0]
        fail ArgumentError, 'Domain name has to be provided' if domain.nil? || domain.empty?

        email = args[1]
        fail ArgumentError, 'Email has to be provided' if email.nil? || email.empty?

        password = args[2]
        fail ArgumentError, 'Password has to be provided' if password.nil? || password.empty?

        GoodData::Command::Domain.add_user(domain, email, password, :client => client)
      end
    end

    c.desc 'List users in domain'
    c.command :list_users do |list_users|
      list_users.action do |global_options, options, args|
        opts = options.merge(global_options)
        client = GoodData.connect(opts)

        domain = args[0]
        fail ArgumentError, 'Domain name has to be provided' if domain.nil? || domain.empty?

        users = GoodData::Command::Domain.list_users(domain, :client => client)
        puts users.map { |u| [u.first_name, u.last_name, u.login].join(',') }
      end
    end
  end
end
