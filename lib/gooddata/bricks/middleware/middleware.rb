# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'aws_middleware'
require_relative 'base_middleware'
require_relative 'bulk_salesforce_middleware'
require_relative 'decode_params_middleware'
require_relative 'dwh_middleware' if RUBY_PLATFORM == 'java'
require_relative 'fs_download_middleware'
require_relative 'gooddata_middleware'
require_relative 'logger_middleware'
require_relative 'params_inspect_middleware'
require_relative 'restforce_middleware'
require_relative 'stdout_middleware'
require_relative 'twitter_middleware'
require_relative 'undot_params_middleware'
