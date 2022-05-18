# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2022 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pmap'
$pmap_default_thread_count = 20 # rubocop:disable GlobalVars

# GoodData Module
module GoodData
end

# Modules
require_relative 'gooddata/core/core'
require_relative 'gooddata/models/models'
require_relative 'gooddata/exceptions/exceptions'
require_relative 'gooddata/helpers/helpers'

# Files
require_relative 'gooddata/bricks/utils'
require_relative 'gooddata/bricks/brick'
require_relative 'gooddata/bricks/base_pipeline'
require_relative 'gooddata/bricks/middleware/base_middleware'
require_relative 'gooddata/bricks/middleware/bench_middleware'
require_relative 'gooddata/bricks/middleware/logger_middleware'
require_relative 'gooddata/bricks/middleware/decode_params_middleware'
require_relative 'gooddata/bricks/middleware/aws_middleware'
require_relative 'gooddata/bricks/middleware/dwh_middleware'
require_relative 'gooddata/bricks/middleware/bench_middleware'

# CSV Downloader
require_relative 'gooddata/core/logging'
require_relative 'gooddata/connection'
