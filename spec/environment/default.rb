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

      set_const :DEFAULT_USERNAME, "tomas.korcak+gem_tester@gooddata.com"
      set_const :TEST_USERNAME, "john.doe@gooddata.com"
      set_const :DEFAULT_PASSWORD, GoodData::Helpers.decrypt('9m5Fe6WIxtkoG9vi2CanKm/CmZMLTpGYzr2duXh75m8=\n', ENV['GD_SPEC_PASSWORD'] || ENV['BIA_ENCRYPTION_KEY'])
      set_const :DEFAULT_DOMAIN, 'gooddata-tomas-korcak-gem-tester'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/3cea1102d5584813506352a2a2a00d95'
      set_const :DEFAULT_SERVER, 'https://secure.gooddata.com'
      set_const :STAGING_URI, 'https://ea-di.staging.intgdc.com/uploads/'
    end

    module ProcessHelper
      set_const :PROCESS_ID, '81fa71a4-69fd-4c58-aa09-66e7f53f4647'
      set_const :DEPLOY_NAME, 'graph.grf'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'we1vvh4il93r0927r809i3agif50d7iz'
      set_const :PROJECT_URL, "/gdc/projects/#{PROJECT_ID}"
      set_const :PROJECT_TITLE, 'GoodTravis'
      set_const :PROJECT_SUMMARY, 'No summary'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '54b90771e4b067429a27a549'
    end
  end
end
