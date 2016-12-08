# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_SERVER, 'https://staging3.intgdc.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/a3700850b92a0a6c097e48369b5d226f'
      set_const :STAGING_URI, 'https://staging3.intgdc.com/gdc/uploads/'
    end

    module ProcessHelper
      set_const :PROCESS_ID, '9c8fd686-6568-4275-bd6e-f0c302a7d8a1'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'wvuz7tq7tzjykubknhabg7dl613oyhtz'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '583c08c8e4b00c626da96110'
    end
  end
end
