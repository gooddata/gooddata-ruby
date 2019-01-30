# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_DOMAIN, 'staging3-lcm-prod'
      set_const :DEFAULT_SERVER, 'https://staging3-lcm-prod.intgdc.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/a4c644d7b42b65c34e5a0f46809f7164'
      set_const :STAGING_URI, 'https://staging3-lcm-prod.intgdc.com/gdc/uploads/'
      set_const :LCM_ENVIRONMENT,
                dev_server: 'staging3-lcm-dev.intgdc.com',
                prod_server: 'staging3-lcm-prod.intgdc.com',
                dev_organization: 'staging3-lcm-dev',
                prod_organization: 'staging3-lcm-prod',
                username: 'rubydev+admin@gooddata.com',
                appstore_deploy_name: 'PRODUCTION_APPSTORE'
    end

    module ProcessHelper
      set_const :PROCESS_ID, 'b671fcfe-f6fd-4379-92c1-3db9eceb1c54'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'rd87oh5rnbf1qhh9vjq5lkgq5v6okei5'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '58ad6260e4b0ee87af79b0b8'
    end
  end
end
