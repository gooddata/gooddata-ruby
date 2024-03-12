# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_DOMAIN, 'staging-lcm-prod'
      set_const :DEFAULT_SERVER, 'https://staging-lcm-prod.intgdc.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/e306b64fb4178785c9cf29c29b5e498a'
      set_const :STAGING_URI, 'https://staging-lcm-prod.intgdc.com/gdc/uploads/'
      set_const :LCM_ENVIRONMENT,
                dev_server: 'staging-lcm-dev.intgdc.com',
                prod_server: 'staging-lcm-prod.intgdc.com',
                dev_organization: 'staging-lcm-dev',
                prod_organization: 'staging-lcm-prod',
                username: 'rubydev+admin@gooddata.com',
                appstore_deploy_name: 'PRODUCTION_APPSTORE'
    end

    module ProcessHelper
      set_const :PROCESS_ID, '756b5f0f-6412-4072-b8e2-f5c33624f497'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'kd39zwi3bii39ewe1skh6ldjfx7ebj7x'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '65f0f0ded245736d3f85dfb6'
    end
  end
end
