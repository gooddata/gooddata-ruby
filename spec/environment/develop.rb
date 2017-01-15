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
      set_const :PROCESS_ID, '193098ca-7c69-4816-a7b0-4418713a1aea'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'n2lyychqhthfb7yc54izgw9p7yov7s21'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '5849273ae4b0fd665ac24b94'
    end
  end
end
