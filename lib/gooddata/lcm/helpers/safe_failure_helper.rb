# Copyright (c) 2010-2019 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module LCM2
    class Helpers
      class << self
        def fail_if_development(msg)
          if ENV['RSPEC_ENV'] == 'test'
            fail msg
          else
            GoodData.logger.error msg
          end
        end
      end
    end
  end
end
