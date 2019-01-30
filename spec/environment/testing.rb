# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_DOMAIN, 'staging2-lcm-prod'
      set_const :DEFAULT_SERVER, 'https://staging2-lcm-prod.intgdc.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/5ad80b895edcc438e5a4418e222733fa'
      set_const :STAGING_URI, 'https://staging2-lcm-prod.intgdc.com/gdc/uploads/'
      set_const :LCM_ENVIRONMENT,
                dev_server: 'staging2-lcm-dev.intgdc.com',
                prod_server: 'staging2-lcm-prod.intgdc.com',
                dev_organization: 'staging2-lcm-dev',
                prod_organization: 'staging2-lcm-prod',
                username: 'rubydev+admin@gooddata.com',
                appstore_deploy_name: 'PRODUCTION_APPSTORE'
    end

    module ProcessHelper
      set_const :PROCESS_ID, '7bc4b678-d1f6-4fb0-b1ee-513f4709bbf1'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'voyb6fcvdngwfyf722vn9cmbv7sq6mf6'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '5acdd513e4b01dce92b23505'
    end
  end
end
