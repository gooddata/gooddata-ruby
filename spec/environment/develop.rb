# encoding: UTF-8

module GoodData
  module Environment
    module ConnectionHelper
      DEFAULT_SERVER = 'https://staging.getgooddata.com'
      DEFAULT_USER_URL = '/gdc/account/profile/6ca71a392e15700a4db4537f441eba39'
    end

    module ProcessHelper
      PROCESS_ID = '94e7be67-5f68-405d-bdeb-93006d50482d'
      DEPLOY_NAME = 'graph/graph.grf'
    end

    module ProjectHelper
      PROJECT_ID = 'k8rzngunca3t9dywmxhqzpgwlui3yg0m'
      PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"
      PROJECT_TITLE = 'GoodTravis'
      PROJECT_SUMMARY = 'No summary'
    end

    module ScheduleHelper
      SCHEDULE_ID = '55953261e4b0a92792febe4e'
    end
  end
end
