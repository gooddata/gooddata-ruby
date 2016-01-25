# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_SERVER, 'https://secure.gooddata.com'
      set_const :DEFAULT_USERNAME, "svarovsky+gem_tester@gooddata.com"
      set_const :TEST_USERNAME, "john.doe@gooddata.com"
      set_const :DEFAULT_PASSWORD, GoodData::Helpers.decrypt('9m5Fe6WIxtkoG9vi2CanKm/CmZMLTpGYzr2duXh75m8=\n', ENV['GD_SPEC_PASSWORD'] || ENV['BIA_ENCRYPTION_KEY'])
      set_const :DEFAULT_DOMAIN, 'gooddata-tomas-svarovsky'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/3cea1102d5584813506352a2a2a00d95'
      set_const :DEFAULT_SERVER, 'https://secure.gooddata.com'
    end

    module ProcessHelper
      set_const :PROCESS_ID, '35ddce15-02b5-4dc5-b161-9fb25b73bd8b'
      set_const :DEPLOY_NAME, 'graph.grf'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'cql548kue571k50guqvaccd10817zyup'
      set_const :PROJECT_URL, "/gdc/projects/#{PROJECT_ID}"
      set_const :PROJECT_TITLE, 'GoodTravis'
      set_const :PROJECT_SUMMARY, 'No summary'
    end

    module ScheduleHelper
      set_const :SCHEDULE_ID, '557ac000e4b041600876e967'
    end
  end
end
