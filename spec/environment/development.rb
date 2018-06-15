# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      encrypted_token = "ciKR76io4KgIUksL6BOF5GW9frsXHAa7JUFqRmc5Wsw=\n"
      key = ENV['GD_SPEC_PASSWORD'] || ENV['BIA_ENCRYPTION_KEY']
      token = GoodData::Helpers.decrypt(encrypted_token, key)
      set_const :GD_PROJECT_TOKEN, token
      set_const :DEFAULT_DOMAIN, 'staging3-lcm-prod'
      set_const :DEFAULT_SERVER, 'https://staging3-lcm-prod.intgdc.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/a4c644d7b42b65c34e5a0f46809f7164'
      set_const :STAGING_URI, 'https://staging3-lcm-prod.intgdc.com/gdc/uploads/'
      set_const :LCM_ENVIRONMENT,
                dev_server: 'staging3-lcm-dev.intgdc.com',
                prod_server: 'staging3-lcm-prod.intgdc.com',
                dev_token: "krw3m2jQREVy9GRJdJi4f4sXcF6r/L515s3Frv8l4eY=\n",
                prod_token: "qq9Mgu0OPqZDpKJyG7R2SM20uvL5Kho+8eAGTvkSTuM=\n",
                vertica_dev_token: "wZ3cvWN8XT40aV9x8xzigrXSbrYGwhH8FaEf6m6IqkA=\n",
                vertica_prod_token: "VV4J66eCRu74qip2ZH2/OVaqgO8gCZ655xXQgiTfrKo=\n",
                dev_organization: 'staging3-lcm-dev',
                prod_organization: 'staging3-lcm-prod',
                username: 'rubydev+admin@gooddata.com',
                password:  "8dP7cCR0LqAyyo4S817bt8bHKfuIteVCW4Y76sGkx78=\n"
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
