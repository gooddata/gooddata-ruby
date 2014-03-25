require 'pp'

require_relative "../shared"

GoodData::CLI.module_eval do
  desc 'Interactive session with gooddata sdk loaded'
  command :console do |c|

    c.action do |global_options, options, args|
      puts "Use 'exit' to quit the live session. Use 'q' to jump out of displaying a large output."
      binding.pry(:quiet => true,
                  :prompt => [proc { |target_self, nest_level, pry|
                    "sdk_live_sesion: "
                  }])
    end
  end
end