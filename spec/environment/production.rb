# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_SERVER, 'https://secure.gooddata.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/d389375454af77f1f5a8edaa13ffe0f9'
      set_const :STAGING_URI, 'https://secure-di.gooddata.com/uploads/'
    end

    module ProcessHelper
      set_const :PROCESS_ID, 'f5d48101-c2d5-49ab-9acb-af6f2e51e09c'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'urdbsii7e840wwdpwjd3pu9l1jdbooah'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '58a5c0c6e4b0831d95092e4a'
    end
  end
end
