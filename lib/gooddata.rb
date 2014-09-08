# encoding: UTF-8

require 'pmap'
$pmap_default_thread_count = 20 # rubocop:disable GlobalVars

# GoodData Module
module GoodData
end

# Modules
require_relative 'gooddata/bricks/bricks'
require_relative 'gooddata/commands/commands'
require_relative 'gooddata/core/core'
require_relative 'gooddata/data/data'
require_relative 'gooddata/exceptions/exceptions'
require_relative 'gooddata/helpers/helpers'
require_relative 'gooddata/models/models'

# Files
require_relative 'gooddata/app/app'
require_relative 'gooddata/client'
require_relative 'gooddata/connection'
require_relative 'gooddata/extract'
require_relative 'gooddata/version'

# Extensions
require_relative 'gooddata/extensions/extensions'
