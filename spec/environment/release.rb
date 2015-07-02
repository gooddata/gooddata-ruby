# encoding: UTF-8

module GoodData
  module Environment
    module ConnectionHelper
      DEFAULT_SERVER = 'https://staging2.getgooddata.com'
      DEFAULT_USER_URL = '/gdc/account/profile/d8b356b30c0c12d1b4b97f56d6706ef2'
    end

    module ProjectHelper
      PROJECT_ID = 'i640il7dyatqmvak24zzr09ypt3ghqu2'
      PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"
      PROJECT_TITLE = 'GoodTravis'
      PROJECT_SUMMARY = 'No summary'
    end
  end
end
