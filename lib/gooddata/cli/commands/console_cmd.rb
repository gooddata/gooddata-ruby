# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pp'

require_relative '../shared'

GoodData::CLI.module_eval do
  desc 'Interactive session with gooddata sdk loaded'
  command :console do |c|
    c.action do |global_options, _options, _args|
      username = global_options[:username]
      fail ArgumentError, 'No username specified' if username.nil? || username.empty?

      password = global_options[:password]
      fail ArgumentError, 'No password specified' if password.nil? || password.empty?

      pid = global_options[:project_id]
      fail ArgumentError, 'No project specified' if pid.nil?

      client = GoodData.connect username, password

      proj = GoodData::Project[pid, :client => client]

      GoodData.with_project(proj, :client => client) do |project|
        fail ArgumentError, 'Wrong project specified' if project.nil?

        puts "Use 'exit' to quit the live session. Use 'q' to jump out of displaying a large output."
        binding.pry(:quiet => true, # rubocop:disable Lint/Debugger
                    :prompt => [proc do |_target_self, _nest_level, _pry|
                      'sdk_live_session: '
                    end])
      end
      client.disconnect
    end
  end
end
