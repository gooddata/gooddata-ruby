# encoding: UTF-8

module GoodData
  module Environment
    module ConnectionHelper
      GD_PROJECT_TOKEN = ENV["GD_PROJECT_TOKEN"]

      DEFAULT_USERNAME = "svarovsky+gem_tester@gooddata.com"
      DEFAULT_PASSWORD = "jindrisska"
      DEFAULT_DOMAIN = 'gooddata-tomas-svarovsky'
      DEFAULT_USER_URL = '/gdc/account/profile/3cea1102d5584813506352a2a2a00d95'
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
