# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_SERVER, 'https://staging.getgooddata.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/6ca71a392e15700a4db4537f441eba39'
    end

    module ProcessHelper
      set_const :PROCESS_ID, '94e7be67-5f68-405d-bdeb-93006d50482d'
      set_const :DEPLOY_NAME, 'graph/graph.grf'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'k8rzngunca3t9dywmxhqzpgwlui3yg0m'
      set_const :PROJECT_URL, "/gdc/projects/#{PROJECT_ID}"
      set_const :PROJECT_TITLE, 'GoodTravis'
      set_const :PROJECT_SUMMARY, 'No summary'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '55953261e4b0a92792febe4e'
    end
  end
end
