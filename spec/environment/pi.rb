# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      pi_env = ENV['GD_PI_ENV'] || 'js-devel'
      set_const :DEFAULT_DOMAIN, 'default'
      set_const :DEFAULT_SERVER, "https://#{pi_env}.na.intgdc.com"

      set_const :DEFAULT_USER_URL, '/gdc/account/profile/a4c644d7b42b65c34e5a0f46809f7164'
      set_const :STAGING_URI, "https://#{pi_env}.na.intgdc.com/gdc/uploads/"

      set_const :GD_PROJECT_TOKEN, GoodData::Helpers.decrypt("dIILGCAVTeRMRHftF1z8bMw/d8HIHMYGsPcUdvJWZRQ=", ENV['GD_SPEC_PASSWORD'] || ENV['BIA_ENCRYPTION_KEY'])

      set_const :DEFAULT_USERNAME, 'bear@gooddata.com'
      set_const :DEFAULT_PASSWORD, GoodData::Helpers.decrypt("xl/HBp7FLeMAlhXfm4Y5sKnpdf51QNNZ2KaXLb98E4c=", ENV['GD_SPEC_PASSWORD'] || ENV['BIA_ENCRYPTION_KEY'])
    end
  end
end
