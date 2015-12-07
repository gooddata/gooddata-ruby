# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../shared'
require_relative '../../commands/auth'

module GoodData
  module CLI
    desc 'Work with your locally stored credentials'
    command :auth do |c|
      c.desc 'Store your credentials to ~/.gooddata so client does not have to ask you every single time'
      c.command :store do |store|
        store.action do |_global_options, _options, _args|
          GoodData::Command::Auth.store
        end
      end

      c.desc 'Clean the credentials'
      c.command :clear do |store|
        store.action do |_global_options, _options, _args|
          GoodData::Command::Auth.unstore
        end
      end
    end
  end
end
