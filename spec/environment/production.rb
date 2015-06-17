# encoding: UTF-8

module GoodData
  module Environment
    module ConnectionHelper
      DEFAULT_SERVER = 'https://secure.gooddata.com'
      DEFAULT_USERNAME = "svarovsky+gem_tester@gooddata.com"
      TEST_USERNAME = "john.doe@gooddata.com"
      DEFAULT_PASSWORD = "jindrisska"
      DEFAULT_DOMAIN = 'gooddata-tomas-svarovsky'
      DEFAULT_USER_URL = '/gdc/account/profile/3cea1102d5584813506352a2a2a00d95'
      DEFAULT_SERVER = 'https://secure.gooddata.com'
    end

    module ProcessHelper
      PROCESS_ID = '35ddce15-02b5-4dc5-b161-9fb25b73bd8b'
      DEPLOY_NAME = 'graph.grf'
    end

    module ProjectHelper
      PROJECT_ID = 'cql548kue571k50guqvaccd10817zyup'
      PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"
      PROJECT_TITLE = 'GoodTravis'
      PROJECT_SUMMARY = 'No summary'
    end

    module ScheduleHelper
      SCHEDULE_ID = '557ac000e4b041600876e967'
    end
  end
end
