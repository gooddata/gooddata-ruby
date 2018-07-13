# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Environment
    module ConnectionHelper
      set_const :LCM_ENVIRONMENT,
                dev_server: 'perf-lcm-dev.prod.com',
                prod_server: 'perf-lcm-prod.prod.com',
                dev_token: "KP3+C5et9WMmYI9zsYUgj9XqvorBEEMmflrAP2jauh/s92O8oaDKnJ7RIaQy\npU1W\n",
                prod_token: "BSH8a/JFKkwwwRpGLZTb2ViOxdeZ+VW0KUny9Mq4AuEalBdeoCbxsfcjCM3W\n6JrK\n",
                vertica_dev_token: "pdFK5RReapLYI0bzM2kz0gtORGJyKiy3tn05uawulcJIP3wDsHQaFjpNJbVF\niVJf\n",
                vertica_prod_token: "d11tBQNJL586wIHelDf1ORvJNEk83GxOPG4f/Azgj3Tdzti4PB5skf6mDVSl\nBB6g\n",
                dev_organization: 'perf-lcm-dev',
                prod_organization: 'perf-lcm-prod',
                username: 'rubydev+admin@gooddata.com',
                password: "8dP7cCR0LqAyyo4S817bt8bHKfuIteVCW4Y76sGkx78=\n"
    end
  end
end
