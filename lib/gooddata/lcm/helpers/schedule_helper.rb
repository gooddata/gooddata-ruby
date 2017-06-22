# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module LCM2
    class Helpers
      class << self
        # Deletes parameters from given schedule that are not present
        # in additional_hidden_params.
        def sanitize_hidden_params_for_transfer(schedule, additional_hidden_params, logger)
          hidden_params = schedule.hidden_params
          complement = hidden_params.keys - additional_hidden_params.keys
          if complement.any?
            logger.warn("Hidden parameter(s) #{complement.join(', ')} are " \
                        'present in the schedule but not in ' \
                        'additional_hidden_params. They will not be ' \
                        'transferred.')
            schedule.hidden_params = hidden_params.except(*complement)
          end
        end
      end
    end
  end
end
