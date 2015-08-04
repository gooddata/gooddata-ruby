# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pp'

require_relative '../shared'
require_relative '../../commands/api'

GoodData::CLI.module_eval do
  desc 'Some basic API stuff directly from CLI'
  arg_name 'info|test|get|delete'
  command :api do |c|
    c.desc 'Info about the API version etc'
    c.command :info do |info|
      info.action do |global_options, options, _args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        pp GoodData::Command::Api.info
      end
    end

    c.desc 'GET request on our API'
    c.command :get do |get|
      get.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        pp GoodData::Command::Api.get(args[0])
      end
    end
  end
end
