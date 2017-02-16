# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_SERVER, 'https://staging2.intgdc.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/3713cbb890fdc5e6eddee18e1ccbc89a'
      set_const :STAGING_URI, 'https://na1-staging2-di.intgdc.com/uploads/'
    end

    module ProcessHelper
      set_const :PROCESS_ID, 'f0aa58a1-2161-471e-bf9e-3cc42b410cd6'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'f021bilepfg8w7vi3yfms63u2h2oc6mb'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '58a5bf4de4b09787f5371e0c'
    end
  end
end
