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
      set_const :PROCESS_ID, 'c96d25f1-e3ce-4356-92f8-d3f1bd0844b1'
      set_const :DEPLOY_NAME, 'hello_world.rb'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'hbx7l4gtfs9okuynea4ngi40gajpjv01'
      set_const :PROJECT_URL, "/gdc/projects/#{PROJECT_ID}"
      set_const :PROJECT_TITLE, 'GoodTravis'
      set_const :PROJECT_SUMMARY, 'No summary'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '5762b6d8e4b060566dba0f10'
    end
  end
end
