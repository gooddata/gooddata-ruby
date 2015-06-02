# encoding: UTF-8

module GoodData
  module Environment
    module ConnectionHelper
      DEFAULT_SERVER = 'https://staging.getgooddata.com'
      DEFAULT_USER_URL = '/gdc/account/profile/6ca71a392e15700a4db4537f441eba39'
    end

    module ProcessHelper
      PROCESS_ID = '2e2cbe45-02fd-4a1a-b735-a37d65ff267d'
      DEPLOY_NAME = 'graph.grf'
    end

    module ProjectHelper
      PROJECT_ID = 'i66l5qezxd96syjo9hgbie8earysh6b7'
      PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"
      PROJECT_TITLE = 'GoodTravis'
      PROJECT_SUMMARY = 'No summary'
    end

    module ScheduleHelper
      SCHEDULE_ID = '556c580ee4b05b1a534f3997'
    end
  end
end
