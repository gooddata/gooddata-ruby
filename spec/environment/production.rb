# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_SERVER, 'https://secure.gooddata.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/3cf6a27afeed76b55caedf292691ac8a'
      set_const :STAGING_URI, 'https://secure-di.gooddata.com/uploads/'
    end

    module ProcessHelper
      set_const :PROCESS_ID, 'f1d78cef-5d4a-4436-a63d-c4e1ef4b15b4'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'zqeflkdchlzjzigrjjnyy5y9yqcqq8kf'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '583c08ebe4b0dcdc1a4d9f62'
    end
  end
end
