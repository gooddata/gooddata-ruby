# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :GD_PROJECT_TOKEN, ENV["GD_PROJECT_TOKEN"]

      set_const :DEFAULT_USERNAME, "svarovsky@gooddata.com"
      set_const :TEST_USERNAME, "john.doe@gooddata.com"
      set_const :DEFAULT_PASSWORD, GoodData::Helpers.decrypt('9m5Fe6WIxtkoG9vi2CanKm/CmZMLTpGYzr2duXh75m8=\n', ENV['GD_SPEC_PASSWORD'] || ENV['BIA_ENCRYPTION_KEY'])
      set_const :DEFAULT_DOMAIN, 'svarovsky-test'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/6e123be5a53dd863df5cf280fdb9c1fd'
      set_const :DEFAULT_SERVER, 'https://staging3.getgooddata.com'
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
