# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/extensions/object'

require 'gooddata/helpers/global_helpers'

module GoodData
  module Environment
    module ConnectionHelper
      set_const :GD_PROJECT_TOKEN, ENV["GD_PROJECT_TOKEN"]
      set_const :GD_MAX_RETRY, Helpers::GD_MAX_RETRY

      set_const :DEFAULT_USERNAME, "rubydev+tester@gooddata.com"
      set_const :DEFAULT_PASSWORD, GoodData::Helpers.decrypt('9m5Fe6WIxtkoG9vi2CanKm/CmZMLTpGYzr2duXh75m8=\n', ENV['GD_SPEC_PASSWORD'] || ENV['BIA_ENCRYPTION_KEY'])
      set_const :DEFAULT_DOMAIN, 'gooddata-rubydev-tester'
      set_const :DEFAULT_USER_URL, ''

      set_const :TEST_USERNAME, "john.doe@gooddata.com"

      set_const :DEFAULT_SERVER, ''
      set_const :STAGING_URI, ''
    end

    module ProcessHelper
      set_const :PROCESS_ID, ''
      set_const :DEPLOY_NAME, 'cc/graph/graph.grf'
    end

    module ProjectHelper
      set_const :PROJECT_ID, ''
      set_const :PROJECT_TITLE, 'GoodTravis'
      set_const :PROJECT_SUMMARY, 'No summary'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, ''
    end
  end
end
