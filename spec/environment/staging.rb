# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      encrypted_token = "2OSh3iq0CJqJMbRJY5VvB9k1AaOus2YOEweAoat+neY=\n"
      key = ENV['GD_SPEC_PASSWORD'] || ENV['BIA_ENCRYPTION_KEY']
      token = GoodData::Helpers.decrypt(encrypted_token, key)
      set_const :GD_PROJECT_TOKEN, token
      set_const :DEFAULT_DOMAIN, 'staging-lcm-prod'
      set_const :DEFAULT_SERVER, 'https://staging-lcm-prod.intgdc.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/e306b64fb4178785c9cf29c29b5e498a'
      set_const :STAGING_URI, 'https://staging-lcm-prod.intgdc.com/gdc/uploads/'
    end

    module ProcessHelper
      set_const :PROCESS_ID, '05cd64ef-db14-49f0-a755-d94d0fb1b3cd'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'ru99pihp3qmj73y1axhu7dx20nxzixu8'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '58ad61cee4b046a545c172b1'
    end
  end
end
