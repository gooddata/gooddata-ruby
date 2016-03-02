# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pathname'

module GoodData
  module Command
    class Projects
      class << self
        def list(options = { client: GoodData.connection })
          client = options[:client]
          client.projects
        end
      end
    end
  end
end
