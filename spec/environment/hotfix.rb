# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_SERVER, 'https://staging2.intgdc.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/d8b356b30c0c12d1b4b97f56d6706ef2'
      set_const :STAGING_URI, 'https://na1-staging2-di.intgdc.com/uploads/'
    end

    module ProcessHelper
      set_const :PROCESS_ID, 'eddb2d5f-c002-4cb4-a0ba-9b9b32c0a40f'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'wrbjys321jmc1ut9tcfode4kh1j2o0k6'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '583c08e1e4b00e7feeb4a2b3'
    end
  end
end
