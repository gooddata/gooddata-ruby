# Copyright (c) 2010-2019 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../shared'
require_relative '../../commands/api'

require 'json'
require 'tty-spinner'

module GoodData
  module CLI
    desc 'Make any requests to the gooddata api'
    command :api do |c|
      %i[get delete post].map do |http_method|
        c.desc "Make a #{http_method} request"
        c.command http_method do |method|
          method.action do |global_options, options, args|
            opts = options.merge(global_options)
            spinner = TTY::Spinner.new ":spinner Calling GoodData API"
            spinner.auto_spin
            res = GoodData::Command::Api.send(http_method, args, opts)
            spinner.stop
            puts res.to_json
          end
        end
      end
    end
  end
end
