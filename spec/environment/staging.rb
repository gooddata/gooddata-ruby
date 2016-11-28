# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_SERVER, 'https://staging.intgdc.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/6ca71a392e15700a4db4537f441eba39'
      set_const :STAGING_URI, 'https://ea-di.staging.intgdc.com/uploads/'
    end

    module ProcessHelper
      set_const :PROCESS_ID, 'd5de77aa-cf96-4018-bbaa-09a905330c8a'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'nz708agdlxos81clatziwpe6o5hph2c8'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '583c08f2e4b0479e793a161f'
    end
  end
end
