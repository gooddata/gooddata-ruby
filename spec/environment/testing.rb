# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :GD_PROJECT_TOKEN, GoodData::Helpers.decrypt("DIRchLbHH1fovLSVEfo3f5aQwHHQ432+PxF3uR5IuNn+iYWz+HZrLtaZ3LVE\n0ZNc\n", ENV['GD_SPEC_PASSWORD'] || ENV['BIA_ENCRYPTION_KEY'])
      set_const :DEFAULT_DOMAIN, 'staging2-lcm-prod'
      set_const :DEFAULT_SERVER, 'https://staging2-lcm-prod.intgdc.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/f099860dd647395377fbf65ae7a78ed4'
      set_const :STAGING_URI, 'https://na1-staging2-di.intgdc.com/uploads/'
    end

    module ProcessHelper
      set_const :PROCESS_ID, '3dddcd0d-1b56-4508-a94b-abea70c7154d'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'fbhs09oddsgezqtn3um5rp08midmbpg5'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '58ad4fbbe4b02e90f6422677'
    end
  end
end
