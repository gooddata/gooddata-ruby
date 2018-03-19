# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      encrypted_token = "c2LNH4s9X32uXC/JT+RROhjss+ZbQpo42sGZFKCYE2U7M1ryQD7bEJjax0gO\ntL8E\n"
      key = ENV['GD_SPEC_PASSWORD'] || ENV['BIA_ENCRYPTION_KEY']
      token = GoodData::Helpers.decrypt(encrypted_token, key)
      set_const :GD_PROJECT_TOKEN, token
      set_const :DEFAULT_DOMAIN, 'staging-lcm-prod'
      set_const :DEFAULT_SERVER, 'https://staging-lcm-prod.intgdc.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/e306b64fb4178785c9cf29c29b5e498a'
      set_const :STAGING_URI, 'https://staging-lcm-prod.intgdc.com/gdc/uploads/'
    end

    module ProcessHelper
      set_const :PROCESS_ID, '83bcb06a-1735-49cd-99e9-58df1c856b06'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'ru99pihp3qmj73y1axhu7dx20nxzixu8'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '58ad61cee4b046a545c172b1'
    end
  end
end
