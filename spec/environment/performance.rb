# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :LCM_ENVIRONMENT,
                dev_server: 'perf1-lcm-dev.prodgdc.com',
                prod_server: 'perf1-lcm-prod.prodgdc.com',
                dev_organization: 'perf1-lcm-dev',
                prod_organization: 'perf1-lcm-prod',
                username: 'rubydev+admin@gooddata.com',
                appstore_deploy_name: 'PUBLIC_APPSTORE'
    end
  end
end
