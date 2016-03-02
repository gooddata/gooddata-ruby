# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :DEFAULT_SERVER, 'https://staging2.getgooddata.com'
      set_const :DEFAULT_USER_URL, '/gdc/account/profile/d8b356b30c0c12d1b4b97f56d6706ef2'
    end

    module ProjectHelper
      set_const :PROJECT_ID, 'i640il7dyatqmvak24zzr09ypt3ghqu2'
      set_const :PROJECT_URL, "/gdc/projects/#{PROJECT_ID}"
      set_const :PROJECT_TITLE, 'GoodTravis'
      set_const :PROJECT_SUMMARY, 'No summary'
    end
  end
end
