# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# GoodData Module
module GoodData
end

# Extensions
require_relative 'gooddata/extensions/extensions'
require 'backports/2.1.0/array/to_h'

# Modules
require_relative 'gooddata/bricks/bricks'
require_relative 'gooddata/commands/commands'
require_relative 'gooddata/core/core'
require_relative 'gooddata/data/data'
require_relative 'gooddata/exceptions/exceptions'
require_relative 'gooddata/helpers/helpers'
require_relative 'gooddata/lcm/lcm'
require_relative 'gooddata/lcm/lcm2'
require_relative 'gooddata/models/models'

# Files
require_relative 'gooddata/app/app'
require_relative 'gooddata/client'
require_relative 'gooddata/connection'
require_relative 'gooddata/extract'
require_relative 'gooddata/version'
