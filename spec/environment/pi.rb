# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      pi_env = ENV['GD_PI_ENV'] || 'pgd-klemtest-002'
      set_const :DEFAULT_DOMAIN, 'default'
      set_const :DEFAULT_SERVER, "https://#{pi_env}.na.intgdc.com"

      set_const :DEFAULT_USER_URL, '/gdc/account/profile/a4c644d7b42b65c34e5a0f46809f7164'
      set_const :STAGING_URI, "https://#{pi_env}.na.intgdc.com/gdc/uploads/"

      set_const :DEFAULT_USERNAME, 'bear@gooddata.com'
      set_const :LCM_ENVIRONMENT,
                dev_server: "#{pi_env}.na.intgdc.com",
                prod_server: "#{pi_env}.na.intgdc.com",
                dev_organization: 'default',
                prod_organization: 'default',
                username: DEFAULT_USERNAME
    end
  end
end
