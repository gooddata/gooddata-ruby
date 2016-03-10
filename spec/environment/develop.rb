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
      set_const :PROCESS_ID, 'e829af78-7dd4-4641-b7fa-74a038b9ea95'
      set_const :DEPLOY_NAME, 'graph/graph.grf'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'wqn630nwbq1afev8qo468ywz19p3y3ti'
      set_const :PROJECT_URL, "/gdc/projects/#{PROJECT_ID}"
      set_const :PROJECT_TITLE, 'GoodTravis'
      set_const :PROJECT_SUMMARY, 'No summary'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '56e17daee4b0a8435609f796'
    end
  end
end
