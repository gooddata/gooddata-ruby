# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_SERVER, 'https://staging.intgdc.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/7a8cf703bb431f8e2e21778c5ba30de9'
      set_const :STAGING_URI, 'https://ea-di.staging.intgdc.com/uploads/'
    end

    module ProcessHelper
      set_const :PROCESS_ID, '5362c571-7fd7-4d28-99eb-93261cd9ec86'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'rf8i143tj9voq15af4qjoj9ib36p1ird'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '58a5c02ce4b046a545c17154'
    end
  end
end
