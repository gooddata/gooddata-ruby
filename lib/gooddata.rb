# encoding: UTF-8

# GoodData Module
module GoodData
end

require 'active_support/all'

# Modules
require File.join(File.dirname(__FILE__), 'gooddata/bricks/bricks')
require File.join(File.dirname(__FILE__), 'gooddata/cli/cli')
require File.join(File.dirname(__FILE__), 'gooddata/commands/commands')
require File.join(File.dirname(__FILE__), 'gooddata/core/core')
require File.join(File.dirname(__FILE__), 'gooddata/models/models')

# Files
require File.join(File.dirname(__FILE__), 'gooddata/client')
require File.join(File.dirname(__FILE__), 'gooddata/connection')
require File.join(File.dirname(__FILE__), 'gooddata/exceptions')
require File.join(File.dirname(__FILE__), 'gooddata/extract')
require File.join(File.dirname(__FILE__), 'gooddata/helpers')
require File.join(File.dirname(__FILE__), 'gooddata/version')
