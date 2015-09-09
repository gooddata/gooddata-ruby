# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      GD_PROJECT_TOKEN = ENV["GD_PROJECT_TOKEN"]


      DEFAULT_USERNAME = "svarovsky@gooddata.com"
      TEST_USERNAME = "john.doe@gooddata.com"
      DEFAULT_PASSWORD = "jindrisska"
      DEFAULT_DOMAIN = 'svarovsky-test'
      DEFAULT_USER_URL = '/gdc/account/profile/6e123be5a53dd863df5cf280fdb9c1fd'
      DEFAULT_SERVER = 'https://staging3.getgooddata.com'
    end

    module ProcessHelper
      PROCESS_ID = '81fa71a4-69fd-4c58-aa09-66e7f53f4647'
      DEPLOY_NAME = 'graph.grf'
    end

    module ProjectHelper
      PROJECT_ID = 'we1vvh4il93r0927r809i3agif50d7iz'
      PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"
      PROJECT_TITLE = 'GoodTravis'
      PROJECT_SUMMARY = 'No summary'
    end

    module ScheduleHelper
      SCHEDULE_ID = '54b90771e4b067429a27a549'
    end
  end
end
