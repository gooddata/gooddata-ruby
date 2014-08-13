# encoding: UTF-8

require 'pp'

require_relative '../shared'

GoodData::CLI.module_eval do
  desc 'Interactive session with gooddata sdk loaded'
  command :console do |c|

    c.action do |global_options, options, args|
      username = global_options[:username]
      fail ArgumentError, 'No username specified' if username.nil? || username.empty?

      password = global_options[:password]
      fail ArgumentError, 'No password specified' if password.nil? || password.empty?

      pid = global_options[:project_id]
      fail ArgumentError, 'No project specified' if pid.nil?

      client = GoodData.connect username, password

      proj = GoodData::Project[pid, :client => client]

      GoodData.with_project(proj) do |project|
        fail ArgumentError, 'Wrong project specified' if project.nil?

        puts "Use 'exit' to quit the live session. Use 'q' to jump out of displaying a large output."
        binding.pry(:quiet => true,
                    :prompt => [proc do |target_self, nest_level, pry|
                      'sdk_live_sesion: '
                    end])
      end
      client.disconnect
    end
  end
end
